# API for sending commands in a transaction.
#
# Used in Redis#multi.
#
class Redis::TransactionApi

  def initialize(@strategy)
  end

  include Redis::Commands
  include Redis::FutureOrientedCommandExecution

  # Aborts the current transaction.
  #
  def discard
    @strategy.discard
  end

  def command(request : Request)
    @strategy.command(request) as Redis::Future
  end
end
