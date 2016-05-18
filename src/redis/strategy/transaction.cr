# :nodoc:
#
# Strategy for sending commands in a transaction.
#
# Used in Redis#multi.
class Redis::Strategy::Transaction < Redis::Strategy::Base
  getter :futures

  def initialize(connection : Connection)
    @connection = connection
    @discarded = false
    @futures = [] of Redis::Future
  end

  def begin
    multi
  end

  def command(request : Request) : Redis::Future
    @connection.queue(request)
    future = Future.new
    @futures << future
    future
  end

  def discard
    flush
    receive_queued_responses
    @discarded = true
    single_command(["DISCARD"])
  end

  def commit
    if @discarded
      return [] of RedisValue
    end

    flush
    receive_queued_responses

    # Commit and receive the actual response values as an array
    results = exec

    fulfill_futures(results)

    results
  end

  # Receive the "QUEUED" responses, one per request
  private def receive_queued_responses
    @connection.receive_queued_responses(number_of_requests)
  end

  private def number_of_requests
    @futures.size
  end

  private def flush
    @connection.flush
  end

  private def fulfill_futures(results)
    results.each_with_index do |result, i|
      @futures[i].value = result
    end
  end

  private def multi
    single_command(["MULTI"])
  end

  private def exec
    single_command(["EXEC"]).as(Array(RedisValue))
  end

  private def single_command(request : Request)
    @connection.send(request)
    @connection.receive
  end
end
