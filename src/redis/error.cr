# Exception for errors that Redis returns.
class Redis::Error < Exception
  def initialize(s)
    super("RedisError: #{s}")
  end
end

class Redis::DisconnectedError < Redis::Error
  def initialize
    super("Disconnected")
  end
end
