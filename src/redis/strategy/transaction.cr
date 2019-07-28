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
    # queue DISCARD
    command(["DISCARD"])

    # commit
    flush

    # discard responses
    @futures.size.times { @connection.receive }
    
    @discarded = true
  end

  def commit
    if @discarded
      return [] of RedisValue
    end

    # queue EXEC
    exec

    # commit
    flush        

    responses = [] of RedisValue

    # receive actual responses
    @futures.each_with_index do |future, i|
      responses << @connection.receive     
    end

    # trim MULTI future & response and EXEC future
    @futures.shift # result of MULTI
    responses.shift # OK
    @futures.pop # result of EXEC
    
    # grab last response as actual results
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
