require "uri"
require "openssl"
require "./redis/commands"
require "./redis/command_execution/value_oriented"

# The class is the main entry point for the Redis client.
#
# **How to use**:
#
# Require the package:
#
# ```
# require "redis"
# ```
#
# Then instantiate this client class:
#
# ```
# redis = Redis.new
# ```
#
# Then you can call Redis commands on the `redis` object:
#
# ```
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

  @connection : Redis::Connection?
  @strategy : Redis::Strategy::Base?

  # Opens a Redis connection
  #
  # **Options**:
  # * host - the host to connect to
  # * port - the port to connect to
  # * unixsocket - instead of using TCP, you can connect to Redis via a Unix domain socket by passing its path here (e.g. "/tmp/redis.sock")
  # * password - the password for authentication against the server. This is a convenience which saves you the extra call to the Redis `auth` command.
  # * database - the number of the database to select. This a convenience which saves you a call a call to `#select`.
  # * ssl - whether SSL should be enabled.
  # * ssl_context - a OpenSSL::SSL::Context::Client.
  # * dns_timeout - the dns timeout.
  # * connect_timeout - the connect timeout.
  # * command_timeout - the command timeout - applies when a command takes too long because the Redis-server is blocked by another command or by a dump.
  # * reconnect - whether we should reconnect when we encounter a disconnected Redis connection.
  # * url - Redis url. If this is given, it overrides all others.
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
  #
  # Example:
  #
  # ```
  # redis = Redis.new(url: "redis://:my-secret-pw@my.redis.com:6380/my-database")
  # ...
  # ```
  def initialize(@host = "localhost", @port = 6379, @unixsocket : String? = nil, @password : String? = nil,
                 @database : Int32? = nil, url = nil, @ssl = false, @ssl_context : OpenSSL::SSL::Context::Client? = nil,
                 @dns_timeout : Time::Span? = nil, @connect_timeout : Time::Span? = nil, @reconnect = true, @command_timeout : Time::Span? = nil,
                 @namespace : String = "")
    if url
      uri = URI.parse url
      @host = uri.host.to_s
      @port = uri.port || 6379
      @password = uri.password
      path = uri.path
      @database = path[1..-1].to_i if path && path.size > 1
      @ssl = uri.scheme == "rediss"
    end

    if @ssl_context
      @ssl = true
    end

    if @ssl && !@ssl_context
      @ssl_context = default_ssl_context
    end

    connect
  end

  # Returns an open Redis connection.

  # :nodoc:
  private def connection : Redis::Connection
    ensure_connection
    # We have just ensured that have a connection.
    @connection.not_nil!
  end

  # Returns the current strategy

  # :nodoc:
  private def strategy : Redis::Strategy::Base
    ensure_connection
    # When we have a connection, we have a strategy too.
    @strategy.not_nil!
  end

  # Makes sure that there is a connection instance in @connection,
  # and thereby implicitly also that there is a strategy instance in @strategy.
  private def ensure_connection
    if @connection
      # Already connected, nothing to be done.
      return
    end

    if @reconnect
      connect
    else
      raise ConnectionLostError.new("Not connected to Redis server and reconnect=false")
    end
  end

  # Connects to Redis.

  # :nodoc:
  private def connect
    @connection = Connection.new(@host, @port, @unixsocket, @ssl_context, @dns_timeout, @connect_timeout, @command_timeout)
    @strategy = Redis::Strategy::SingleStatement.new(@connection.not_nil!)
    strategy.command(["AUTH", @password]) if @password
    strategy.command(["SELECT", @database.to_s]) if @database
  end

  # :nodoc:
  private def default_ssl_context
    context = OpenSSL::SSL::Context::Client.new
    context.ciphers = "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH"
    context.add_options(OpenSSL::SSL::Options::NO_SSL_V2 | OpenSSL::SSL::Options::NO_SSL_V3)
    context
  end

  # Opens a Redis connection, yields the given block with a Redis object and closes the connection.
  #
  # **Options**:
  # * host - the host to connect to
  # * port - the port to connect to
  # * unixsocket - instead of using TCP, you can connect to Redis via a Unix domain socket by passing its path here (e.g. "/tmp/redis.sock")
  # * password - the password for authentication against the server. This is a convenience which saves you the extra call to the Redis `auth` command.
  # * database - the number of the database to select. This a convenience which saves you a call a call to `#select`.
  # * ssl - whether SSL should be enabled.
  # * ssl_context - a OpenSSL::SSL::Context::Client.
  # * dns_timeout - the dns timeout.
  # * connect_timeout - the connect timeout.
  # * command_timeout - the command timeout - applies when a command takes too long because the Redis-server is blocked by another command or by a dump.
  # * reconnect - whether we should reconnect when we encounter a disconnected Redis connection.
  # * url - Redis url. If this is given, it overrides all others.
  #
  # Example:
  #
  # ```
  # Redis.open do |redis|
  #   redis.incr("counter")
  # end
  # ```
  def self.open(host = "localhost", port = 6379, unixsocket = nil, password = nil,
                database = nil, url = nil, ssl = false, ssl_context = nil,
                dns_timeout = nil, connect_timeout = nil, reconnect = true, command_timeout = nil,
                namespace : String = "")
    redis = Redis.new(host, port, unixsocket, password, database, url, ssl, ssl_context, dns_timeout, connect_timeout, reconnect, command_timeout, namespace)
    begin
      yield(redis)
    ensure
      redis.close
    end
  end

  # Closes the Redis connection.
  def close
    @connection.try(&.close)
    @connection = nil
    @strategy = nil
  end

  # Returns the server URL for this client.
  def url
    scheme = @ssl ? "rediss" : "redis"
    if @unixsocket
      "#{scheme}://#{@unixsocket}/#{@database || 0}"
    else
      "#{scheme}://#{@host}:#{@port}/#{@database || 0}"
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
    pipeline_strategy = Redis::Strategy::Pipeline.new(connection)
    pipeline_api = Redis::PipelineApi.new(pipeline_strategy, @namespace.to_s)
    yield(pipeline_api)
    pipeline_strategy.commit.as(Array(RedisValue))
  rescue ex : Redis::ConnectionError | Redis::CommandTimeoutError
    close
    raise ex
  ensure
    if @connection
      @strategy = Redis::Strategy::SingleStatement.new(@connection.not_nil!)
    end
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
    transaction_strategy = Redis::Strategy::Transaction.new(connection)
    transaction_strategy.begin
    transaction_api = Redis::TransactionApi.new(transaction_strategy, @namespace.to_s)
    yield(transaction_api)
    transaction_strategy.commit.as(Array(RedisValue))
  rescue ex : Redis::ConnectionError | Redis::CommandTimeoutError
    close
    raise ex
  ensure
    if @connection
      @strategy = Redis::Strategy::SingleStatement.new(@connection.not_nil!)
    end
  end

  # This is an internal method.
  #
  # Executes a Redis command.
  #
  # **Return value**: a RedisValue (never a Future)

  # :nodoc:
  def command(request : Request)
    with_reconnect do
      strategy.command(request).as(RedisValue)
    end
  end

  # :nodoc:
  private def with_reconnect
    yield
  rescue ex : Redis::ConnectionError
    close
    if @reconnect
      # Implicitly reconnect by retrying the given block.
      yield
    else
      # Just tell the caller that the connection died.
      raise ex
    end
  rescue ex : Redis::CommandTimeoutError
    close
    raise ex
  end
end

require "./**"
