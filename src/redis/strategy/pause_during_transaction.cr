# :nodoc:
#
# Strategy for the original Redis object that prevents commands from being sent
# while in transaction mode.
#
# Used in Redis#multi.
class Redis::Strategy::PauseDuringTransaction < Redis::Strategy::Base
  def command(request : Request)
    raise Redis::Error.new("We are in a multi block - call methods on the multi block argument instead of the Redis object")
  end
end
