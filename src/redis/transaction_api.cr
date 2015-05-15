require "./command_execution/future_oriented"

# API for sending commands in a transaction.
#
# Used in Redis#multi.
#
#
# Example:
#
# ```
# redis.multi do |multi|
#     multi.set("foo1", "first")
#     multi.set("foo2", "second")
# end
# ```
#
# In this example, the `multi` object passed to the block is a TransactionApi
# object.
class Redis::TransactionApi

  def initialize(@strategy)
  end

  include Redis::Commands
  include Redis::CommandExecution::FutureOriented

  # Aborts the current transaction.
  #
  def discard
    @strategy.discard
  end

  def command(request : Request)
    @strategy.command(request) as Redis::Future
  end
end
