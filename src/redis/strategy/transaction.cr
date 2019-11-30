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
    # Queue DISCARD
    command(["DISCARD"])

    # Send everything to Redis
    flush

    # Discard responses
    @futures.size.times { @connection.receive }

    @discarded = true
  end

  def commit
    if @discarded
      return [] of RedisValue
    end

    # Queue COMMIT
    exec

    # Send everything to Redis
    flush

    responses = [] of RedisValue

    # receive actual responses
    @futures.each do |future|
      responses << @connection.receive
    end

    # Trim MULTI future & response and EXEC future
    @futures.shift  # Result of MULTI
    responses.shift # "OK"
    @futures.pop    # Result of EXEC

    # Grab remaining responses as actual results
    results = responses.pop.as(Array(RedisValue))

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

  # queue MULTI
  private def multi
    command(["MULTI"])
  end

  # queue EXEC
  private def exec
    command(["EXEC"])
  end

  private def single_command(request : Request)
    @connection.send(request)
    @connection.receive
  end
end
