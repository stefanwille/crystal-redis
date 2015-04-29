# Command interface for sending commands in pipelined mode.
#
# Used in Redis#pipelined.
#
class Redis::Pipeline
  def initialize(connection)
    @connection = connection
    @futures = [] of Redis::Future
  end

  def command(request : Request)
    @connection.queue(request)
    future = Future.new
    @futures << future
    future
  end

  def commit
    flush

    results = [] of RedisValue
    @futures.each_with_index do |future, i|
      response = @connection.receive
      results << response
      future.value = response
    end
    results
  end

  def discard
    raise Redis::Error.new("We are in pipelined mode - nothing to discard")
  end

  private def flush
    @connection.flush
  end
end
