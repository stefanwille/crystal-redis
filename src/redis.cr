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

  @client : Redis::Client?
  @sslcxt : OpenSSL::SSL::Context::Client?

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
                 @database : Int32? = nil, url = nil, ssl = false, ssl_context = nil,
                 @dns_timeout : Time::Span? = nil, @connect_timeout : Time::Span? = nil, @reconnect = true)
    if url
      uri = URI.parse url
      @host = uri.host.to_s
      @port = uri.port || 6379
      @password = uri.password
      path = uri.path
      @database = path[1..-1].to_i if path && path.size > 1
      @sslcxt = default_ssl_context if uri.scheme == "rediss"
    end

    if ssl_context
      @sslcxt = ssl_context
    elsif ssl && !ssl_context
      @sslcxt = default_ssl_context
    end

    @url = if unixsocket
             "redis://#{@unixsocket}/#{@database || 0}"
           elsif ssl || ssl_context
             "rediss://#{@host}:#{@port}/#{@database || 0}"
           else
             "redis://#{@host}:#{@port}/#{@database || 0}"
           end

    # instantinate it
    client
  end

  def client
    @client ||= Redis::Client.new(@host, @port, @unixsocket, @password, @database, @sslcxt, @dns_timeout, @connect_timeout)
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
                dns_timeout = nil, connect_timeout = nil, reconnect = true)
    redis = Redis.new(host, port, unixsocket, password, database, url, ssl, ssl_context, dns_timeout, connect_timeout, reconnect)
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
    client.strategy = Redis::Strategy::PauseDuringPipeline.new
    pipeline_strategy = Redis::Strategy::Pipeline.new(client.connection)
    pipeline_api = Redis::PipelineApi.new(pipeline_strategy)
    yield(pipeline_api)
    pipeline_strategy.commit.as(Array(RedisValue))
  rescue ex : Redis::ConnectionError
    close
    raise ex
  ensure
    if _client = @client
      _client.strategy = Redis::Strategy::SingleStatement.new(_client.connection)
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
    client.strategy = Redis::Strategy::PauseDuringTransaction.new
    transaction_strategy = Redis::Strategy::Transaction.new(client.connection)
    transaction_strategy.begin
    transaction_api = Redis::TransactionApi.new(transaction_strategy)
    yield(transaction_api)
    transaction_strategy.commit.as(Array(RedisValue))
  rescue ex : Redis::ConnectionError
    close
    raise ex
  ensure
    if _client = @client
      _client.strategy = Redis::Strategy::SingleStatement.new(_client.connection)
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
      client.strategy.command(request).as(RedisValue)
    end
  end

  # :nodoc:
  private def with_reconnect
    yield
  rescue ex : Redis::ConnectionError
    close
    if @reconnect
      # Implicitly reconnect by retrying the given block
      yield
    else
      # Just tell the caller that the connection died.
      raise ex
    end
  end

  # Closes the Redis connection.
  def close
    @client.try(&.close)
    @client = nil
  end
end

require "./**"
