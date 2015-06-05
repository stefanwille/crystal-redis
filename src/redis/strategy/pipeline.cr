#:nodoc:
#
# Strategy for sending commands in pipelined mode.
#
# Used in Redis#pipelined.
class Redis::Strategy::Pipeline < Redis::Strategy::Base
  MAX_OUTSTANDING_RESPONSES = 10_000

  def initialize(@connection)
    @futures = [] of Redis::Future
    @results = [] of RedisValue
    @outstanding_responses = 0
  end

  def command(request : Request) : Redis::Future
    @connection.queue(request)
    future = Future.new
    @futures << future
    # Don't send too many requests without reading their responses.
    # Otherwise we can trigger issue #2 (https://github.com/stefanwille/crystal-redis/issues/2)
    @outstanding_responses += 1
    limit_outstanding_responses
    future
  end

  def commit
    receive_all_outstanding_responses
    give_each_future_its_value
    @results
  end

  private def limit_outstanding_responses
    if @outstanding_responses > MAX_OUTSTANDING_RESPONSES
      receive_all_outstanding_responses
    end
  end

  private def receive_all_outstanding_responses
    flush

    @outstanding_responses.times do |i|
      response = @connection.receive
      @results << response
    end
    @outstanding_responses = 0
  end

  private def give_each_future_its_value
    @futures.each_with_index do |future, i|
      future.value = @results[i]
    end
  end

  private def flush
    @connection.flush
  end
end

