# Depending on the state that the Redis client is in,
# requests and responses need to be treated differently.
#
# The behaviour is implemented using the Strategy design pattern,
# and this is the base class for all strategies.
#
abstract class Redis::Strategy::Base
  def begin
    raise "Redis: begin: We are not in a pipeline or multi"
  end

  def discard
    raise "Redis: discard: We are not in a pipeline or multi"
  end

  def commit
    raise "Redis: commit: We are not in a pipeline or multi"
  end
end

