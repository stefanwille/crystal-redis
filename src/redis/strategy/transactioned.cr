# Strategy for sending commands in a transaction.
#
# Used in Redis#multi.
#
class Redis::Strategy::Transactioned < Redis::Strategy::Base
  def command(request : Request)
    raise Redis::Error.new("We are in a multi block - call methods on the multi block argument instead of the Redis object")
  end
end
