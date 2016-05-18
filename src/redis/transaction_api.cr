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
#   multi.set("foo1", "first")
#   multi.set("foo2", "second")
# end
# ```
#
# In this example, the `multi` object passed to the block is a TransactionApi
# object.
class Redis::TransactionApi
  @strategy : Redis::Strategy::Transaction

  def initialize(@strategy)
  end

  include Redis::Commands
  # :nodoc:
  include Redis::CommandExecution::FutureOriented

  # Aborts the current transaction.
  #
  # **Example**:
  #
  # ```
  # redis.multi do |multi|
  #   multi.set("foo", "the new value")
  #   multi.discard
  # end
  # ```
  def discard
    @strategy.discard
  end

  # :nodoc:
  def command(request : Request) : Redis::Future
    @strategy.command(request)
  end
end
