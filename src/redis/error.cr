# Exception for errors that Redis returns.
class Redis::Error < Exception
  def initialize(s)
    super("RedisError: #{s}")
  end
end
