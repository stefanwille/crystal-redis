require "./redis/commands"
require "./redis/command_execution/value_oriented"

# The class is the main entry point for the Redis client.
#
# **How to use**:
#
# Require the package:
#
# ```crystal
#   require "redis"
# ```
#
# Then instantiate this client class:
#
# ```crystal
#   redis = Redis.new
# ```
#
# Then you can call Redis commands on the `redis` object:
#
# ```crystal
#   redis.set("foo", "bar")
#   redis.get("foo")
#   redis.incr("visitors")
# ```
#
# See the mixin module <a href="Redis/Commands.html" target="main">Commands</a> for most
# of the available Redis commands such as #incr, #rename, and so on.
class Redis
  alias RedisValue = Nil | Int32 | Int64 | String | Array(RedisValue)
  alias Request = Array(RedisValue)

  # Opens a Redis connection
  #
  # Example:
  #
  # ```
  # redis = Redis.new
  # redis.incr("counter")
  # redis.close
  # ```
  #
  # **Options**:
  # * host - the host to connect to
  # * port - the port to connect to
  # * unixsocket - instead of using TCP, you can connect to Redis via a Unix domain socket by passing its path here (e.g. "/tmp/redis.sock")
  def initialize(host = "localhost", port = 6379, unixsocket = nil)
    @connection = Connection.new(host, port, unixsocket)
    @strategy = Redis::Strategy::SingleStatement.new(@connection)
  end

  # Opens a Redis connection, yields the given block with a Redis object and closes the connection.
  #
  # Example:
  #
  # ```
  # Redis.open do |redis|
  #    redis.incr("counter")
  # end
  # ```
  #
  # **Options**:
  # * host - the host to connect to
  # * port - the port to connect to
  # * unixsocket - instead of using TCP, you can connect to Redis via a Unix domain socket by passing its path here (e.g. "/tmp/redis.sock")
  def self.open(host = "localhost", port = 6379, unixsocket = nil)
    redis = Redis.new(host, port, unixsocket)
    begin
      yield(redis)
    ensure
      redis.close
    end
  end

  # Most Redis client API methods are defined in this module.
  include Redis::Commands

  # The methods used in Redis::Command are implemented in the following module.
  # For Future based responses, there is an alternative module
  # calls Redis::CommandExecution::FutureOriented
  include Redis::CommandExecution::ValueOriented

  # Sends Redis commands in pipeline mode.
  #
  # Yields its block. The block receives as argument
  # an object that has the same API as this class, except
  # it participates in pipelining and all Redis commands return Futures.
  #
  # Example:
  # ```
  # redis.pipelined do |pipeline|
  #     pipeline.set("foo1", "first")
  #     pipeline.set("foo2", "second")
  # end
  # ```
  #
  # See the examples directory for more examples.
  #
  # **Return value**: an array with all the responses
  # - one element for each executed command.
  def pipelined
    @strategy = Redis::Strategy::PauseDuringPipeline.new
    pipeline_strategy = Redis::Strategy::Pipeline.new(@connection)
    pipeline_api = Redis::PipelineApi.new(pipeline_strategy)
    yield(pipeline_api)
    pipeline_strategy.commit as Array(RedisValue)
  ensure
    @strategy = Redis::Strategy::SingleStatement.new(@connection)
  end


  # Sends Redis commands in transaction mode.
  #
  # Yields its block. The block receives as argument
  # an object that has the same API as this class, except:
  #   * it participates in the transaction
  #   * all the Redis commands return Futures
  #   * there is an additional method #discard that will abort the transaction.
  #
  # Example:
  # ```
  # redis.multi do |multi|
  #     multi.set("foo1", "first")
  #     multi.set("foo2", "second")
  # end
  # ```
  #
  # See the examples directory for more examples.
  #
  # **Return value**: an array with all the responses
  # - one element for each executed command.
  def multi
    @strategy = Redis::Strategy::PauseDuringTransaction.new
    transaction_strategy = Redis::Strategy::Transaction.new(@connection)
    transaction_strategy.begin
    transaction_api = Redis::TransactionApi.new(transaction_strategy)
    yield(transaction_api)
    transaction_strategy.commit as Array(RedisValue)
  ensure
    @strategy = Redis::Strategy::SingleStatement.new(@connection)
  end

  # This is an internal method.
  #
  # Executes a Redis command.
  #
  # **Return value**: a RedisValue (never a Future)
  def command(request : Array(RedisValue))
    @strategy.command(request) as RedisValue
  end

  # Closes the Redis connection.
  def close
    @connection.close
  end
end

require "./**"

