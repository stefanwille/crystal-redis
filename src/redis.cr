require "./redis/commands"

# The entry point for the Redis client.
#
# See https://github.com/stefanwille/crystal-redis for documentation.
class Redis
  alias RedisValue = Nil | Int32 | Int64 | String | Array(RedisValue)
  alias Request = Array(RedisValue)

  # Most client API methods are defined in this module:
  include Redis::Commands

  # Opens a Redis connection
  def initialize(host = "localhost", port = 6379, unixsocket = nil)
    @connection = Connection.new(host, port, unixsocket)
    @strategy = Redis::Strategy::SingleStatement.new(@connection)
  end

  # Opens a Redis connection, yields the block and closes the connection.
  def self.open(host = "localhost", port = 6379, unixsocket = nil)
    redis = Redis.new(host, port, unixsocket)
    begin
      yield(redis)
    ensure
      redis.close
    end
  end

  # Sends Redis commands in pipeline mode.
  #
  # Yields its block. The block receives as argument
  # an object that has the same API as this class, except
  # all the Redis commands return Futures.
  #
  # See the examples directory for an example.
  def pipelined
    @strategy = Redis::Strategy::Pipelined.new
    pipeline = Redis::Pipeline.new(@connection)
    future_client = FutureClient.new(pipeline)
    yield(future_client)
    pipeline.commit as Array(RedisValue)
  ensure
    @strategy = Redis::Strategy::SingleStatement.new(@connection)
  end


  # Sends Redis commands in transaction mode.
  #
  # Yields its block. The block receives as argument
  # an object that has the same API as this class, except
  # all the Redis commands return Futures, the there is
  # an additional method #discard that will abort the
  # transaction.
  #
  # See the examples directory for examples.
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

  # Executes a Redis command and casts it to the correct type.
  def integer_command(request : Request)
    command(request) as Int64
  end

  # Executes a Redis command and casts it to the correct type.
  def integer_or_nil_command(request : Request)
    command(request) as Int64?
  end

  # Executes a Redis command and casts it to the correct type.
  def integer_array_command(request : Request)
    command(request) as Array(RedisValue)
  end

  # Executes a Redis command and casts it to the correct type.
  def string_command(request : Request)
    command(request) as String
  end

  # Executes a Redis command and casts the response to the correct type.
  def string_or_nil_command(request : Request)
    command(request) as String?
  end

  # Executes a Redis command and casts the response to the correct type.
  def string_array_command(request : Request)
    command(request) as Array(RedisValue)
  end

  # Executes a Redis command and casts the response to the correct type.
  def string_array_or_integer_command(request : Request)
    command(request) as Array(RedisValue) | Int64
  end

  # Executes a Redis command and casts the response to the correct type.
  def string_array_or_string_command(request : Request)
    command(request) as Array(RedisValue) | String
  end

  # Executes a Redis command and casts the response to the correct type.
  def array_or_nil_command(request : Request)
    command(request) as Array(RedisValue)?
  end

  # Executes a Redis command that has no relevant response.
  def void_command(request : Request)
    command(request)
  end

  # Executes a Redis command.
  def command(request : Array(RedisValue))
    @strategy.command(request) as RedisValue | Future
  end

  # Closes the Redis connection.
  def close
    @connection.close
  end
end

require "./**"

