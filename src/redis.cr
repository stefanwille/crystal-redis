require "./redis/commands"
require "./redis/command_execution/value_oriented"

# The class is the main entry point for the Redis client.
#
# **How to use**:
#
# Require the package:
#
# ```crystal
# require "redis"
# ```
#
# Then instantiate this client class:
#
# ```crystal
# redis = Redis.new
# ```
#
# Then you can call Redis commands on the `redis` object:
#
# ```crystal
# redis.set("foo", "bar")
# redis.get("foo")
# redis.incr("visitors")
# ```
#
# See the mixin module [Commands](Redis/Commands.html) for most
# of the available Redis commands such as #incr, #rename, and so on.
#
# **Multithreading / Coroutines**
#
# Please mind that a Redis object can't be shared across multiple threads/coroutines!
# Each thread/coroutine that wants to talk to Redis needs its own Redis object instance.
class Redis
  # A value from the Redis type system.

  # :nodoc:
  alias RedisValue = Nil | Int32 | Int64 | String | Array(RedisValue)

  # A Redis request.

  # :nodoc:
  alias Request = Array(RedisValue)

  # Returns the server URI for this client.
  getter! url : String

  @strategy : Redis::Strategy::Base

  # Opens a Redis connection
  #
  # **Options**:
  # * host - the host to connect to
  # * port - the port to connect to
  # * unixsocket - instead of using TCP, you can connect to Redis via a Unix domain socket by passing its path here (e.g. "/tmp/redis.sock")
  # * password - the password for authentication against the server. This is a convenience which saves you the extra call to the Redis `auth` command.
  # * database - the number of the database to select. This a convenience which saves you a call a call to `#select`.
  #
  # Example:
  #
  # ```
  # redis = Redis.new
  # redis.incr("counter")
  # redis.close
  # ```
  #
  # Example:
  #
  # ```
  # redis = Redis.new(host: "localhost", port: 6379)
  # ...
  # ```
  #
  # Example:
  #
  # ```
  # redis = Redis.new(unixsocket: "/tmp/redis.sock")
  # ...
  # ```
  def initialize(host = "localhost", port = 6379, unixsocket = nil, password = nil, database = nil)
    @connection = Connection.new(host, port, unixsocket)
    @strategy = Redis::Strategy::SingleStatement.new(@connection)
    @url = if unixsocket
             "redis://#{unixsocket}/#{database ? database : 0}"
           else
             "redis://#{host}:#{port}/#{database ? database : 0}"
           end

    if password
      auth(password)
    end

    if database
      self.select(database)
    end
  end

  # Opens a Redis connection, yields the given block with a Redis object and closes the connection.
  #
  # **Options**:
  # * host - the host to connect to
  # * port - the port to connect to
  # * unixsocket - instead of using TCP, you can connect to Redis via a Unix domain socket by passing its path here (e.g. "/tmp/redis.sock")
  # * password - the password for authentication against the server. This is a convenience which saves you the extra call to the Redis `auth` command.
  # * database - the number of the database to select. This a convenience which saves you a call a call to `#select`.
  #
  # Example:
  #
  # ```
  # Redis.open do |redis|
  #   redis.incr("counter")
  # end
  # ```
  def self.open(host = "localhost", port = 6379, unixsocket = nil, password = nil, database = nil)
    redis = Redis.new(host, port, unixsocket, database)
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
  # called Redis::CommandExecution::FutureOriented.
  include Redis::CommandExecution::ValueOriented

  # Sends Redis commands in pipeline mode.
  #
  # Yields its block. The block receives as argument
  # an object that has the same API as this class, except
  # it participates in pipelining and all Redis commands return Futures.
  #
  # **Return value**: an array with all the responses
  # - one element for each executed command.
  #
  # Example:
  #
  # ```
  # redis.pipelined do |pipeline|
  #   pipeline.set("foo1", "first")
  #   pipeline.set("foo2", "second")
  # end
  # ```
  #
  # See the [examples repository](https://github.com/stefanwille/crystal-redis-examples) for more examples.
  def pipelined
    @strategy = Redis::Strategy::PauseDuringPipeline.new
    pipeline_strategy = Redis::Strategy::Pipeline.new(@connection)
    pipeline_api = Redis::PipelineApi.new(pipeline_strategy)
    yield(pipeline_api)
    pipeline_strategy.commit.as(Array(RedisValue))
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
  # **Return value**: an array with all the responses
  # - one element for each executed command.
  #
  # Example:
  #
  # ```
  # redis.multi do |multi|
  #   multi.set("foo1", "first")
  #   multi.set("foo2", "second")
  # end
  # ```
  #
  # See the [examples repository](https://github.com/stefanwille/crystal-redis-examples) for more examples.
  def multi
    @strategy = Redis::Strategy::PauseDuringTransaction.new
    transaction_strategy = Redis::Strategy::Transaction.new(@connection)
    transaction_strategy.begin
    transaction_api = Redis::TransactionApi.new(transaction_strategy)
    yield(transaction_api)
    transaction_strategy.commit.as(Array(RedisValue))
  ensure
    @strategy = Redis::Strategy::SingleStatement.new(@connection)
  end

  # This is an internal method.
  #
  # Executes a Redis command.
  #
  # **Return value**: a RedisValue (never a Future)

  # :nodoc:
  def command(request : Request)
    @strategy.command(request).as(RedisValue)
  end

  # Closes the Redis connection.
  def close
    @connection.close
  end
end

require "./**"
