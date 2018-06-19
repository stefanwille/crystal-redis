require "pool/connection"

class Redis::PooledClient
  getter pool

  def initialize(*args, pool_size = 5, pool_timeout = 5.0, **args2)
    @pool = ConnectionPool(Redis).new(capacity: pool_size, timeout: pool_timeout) do
      Redis.new(*args, **args2)
    end
  end

  macro method_missing(call)
    with_pool_connection { |conn| conn.{{call}} }
  end

  private def with_pool_connection
    conn = begin
      @pool.checkout
    rescue IO::Timeout
      raise Redis::PoolTimeoutError.new("No ready connection (used #{@pool.size} from #{@pool.capacity})")
    end

    begin
      yield(conn)
    ensure
      @pool.checkin(conn)
    end
  end

  def subscribe(*channels, &callback_setup_block : Redis::Subscription ->)
    @pool.with_pool_connection &.subscribe(*channels) { |s| callback_setup_block.call(s) }
  end

  def psubscribe(*channel_patterns, &callback_setup_block : Redis::Subscription ->)
    @pool.with_pool_connection &.subscribe(*channel_patterns) { |s| callback_setup_block.call(s) }
  end
end
