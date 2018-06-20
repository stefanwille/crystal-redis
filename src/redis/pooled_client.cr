require "pool/connection"

# A Redis client object that can be shared across multiple fibers.
# It is backed by a connection pool of `Redis` instances and will automatically allocate and free these instances from/to the pool, per command.
#
# Example usage:
#
# ```Crystal
# redis = Redis::PooledClient.new(host: ..., port: ..., ..., pool_size: 5)
# 10.times do |i|
#   spawn do
#     redis.set("foo#{i}", "bar")
#     redis.get("foo#{i}") # => "bar"
#   end
# end
# ```
#
# Here 10 fibers access the same `Redis::PooledClient` instance while automatically sharing 5 Redis connections.
#
class Redis::PooledClient
  # The connection pool.
  # See [https://github.com/ysbaddaden/pool](https://github.com/ysbaddaden/pool)
  getter pool

  # Accepts the same connection parameters like a `Redis` instance, plus the documented ones.
  #
  # * pool_size - the number of `Redis` to hold in the connection pool.
  # * pool_timeout - the time to wait for a `Redis` instance to become available from the pool before dying with `Redis::PoolTimeoutError`.
  def initialize(*args, pool_size = 5, pool_timeout = 5.0, **args2)
    @pool = ConnectionPool(Redis).new(capacity: pool_size, timeout: pool_timeout) do
      Redis.new(*args, **args2)
    end
  end

  macro method_missing(call)
    # Delegates all Redis commands to a `Redis` instance from the connection pool.
    with_pool_connection { |conn| conn.{{call}} }
  end

  # Executes the given block, passing it a Redis client from the connection pool.
  private def with_pool_connection
    conn = begin
      @pool.checkout
    rescue IO::Timeout
      raise Redis::PoolTimeoutError.new("No free connection (used #{@pool.size} of #{@pool.capacity}) after timeout of #{@pool.timeout}s")
    end

    begin
      yield(conn)
    ensure
      @pool.checkin(conn)
    end
  end

  def subscribe(*channels, &callback_setup_block : Redis::Subscription ->)
    with_pool_connection &.subscribe(*channels) { |s| callback_setup_block.call(s) }
  end

  def psubscribe(*channel_patterns, &callback_setup_block : Redis::Subscription ->)
    with_pool_connection &.subscribe(*channel_patterns) { |s| callback_setup_block.call(s) }
  end
end
