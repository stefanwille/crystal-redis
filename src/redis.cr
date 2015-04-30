require "./redis/commands"

# The entry point for the Redis client.
#
# See https://github.com/stefanwille/crystal-redis for documentation.
class Redis
  alias RedisValue = Nil | Int32 | Int64 | String | Array(RedisValue)
  alias Request = Array(RedisValue)

  include Redis::Commands

  def initialize(host = "localhost", port = 6379, unixsocket = nil)
    @connection = Connection.new(host, port, unixsocket)
    @strategy = Redis::Strategy::SingleStatement.new(@connection)
  end

  def self.open(host = "localhost", port = 6379, unixsocket = nil)
    redis = Redis.new(host, port, unixsocket)
    begin
      yield(redis)
    ensure
      redis.close
    end
  end

  def pipelined
    @strategy = Redis::Strategy::Pipelined.new
    pipeline = Redis::Pipeline.new(@connection)
    future_client = FutureClient.new(pipeline)
    yield(future_client)
    pipeline.commit as Array(RedisValue)
  ensure
    @strategy = Redis::Strategy::SingleStatement.new(@connection)
  end

  def multi
    @strategy = Redis::Strategy::Transactioned.new
    transaction = Redis::Transaction.new(@connection)
    transaction.begin
    future_client = FutureClient.new(transaction)
    yield(future_client)
    transaction.commit as Array(RedisValue)
  ensure
    @strategy = Redis::Strategy::SingleStatement.new(@connection)
  end

  def integer_command(request : Request)
    command(request) as Int64
  end

  def integer_or_nil_command(request : Request)
    command(request) as Int64?
  end

  def integer_array_command(request : Request)
    command(request) as Array(RedisValue)
  end

  def string_command(request : Request)
    command(request) as String
  end

  def string_or_nil_command(request : Request)
    command(request) as String?
  end

  def string_array_command(request : Request)
    command(request) as Array(RedisValue)
  end

  def string_array_or_integer_command(request : Request)
    command(request) as Array(RedisValue) | Int64
  end

  def string_array_or_string_command(request : Request)
    command(request) as Array(RedisValue) | String
  end

  def array_or_nil_command(request : Request)
    command(request) as Array(RedisValue)?
  end

  def void_command(request : Request)
    command(request)
  end

  def command(request : Array(RedisValue))
    @strategy.command(request) as RedisValue | Future
  end

  def close
    @connection.close
  end

end

require "./**"

