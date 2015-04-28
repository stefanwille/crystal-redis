# Strategy for sending commands in a pipeline.
#
# Used in Redis#pipelined.
#
class Redis::Strategy::Pipeline < Redis::Strategy::Base
  def initialize(connection)
    @connection = connection
    @futures = [] of Redis::Future
  end

  def begin
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

  private def flush
    @connection.flush
  end
end
