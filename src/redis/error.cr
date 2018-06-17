# Exception for errors raised by this shard.
class Redis::Error < Exception
end

# An error that makes the connection unusable.
class Redis::ConnectionError < Redis::Error
end

# Raised when connecting to the Redis server is not possible.
class Redis::CannotConnectError < Redis::ConnectionError
end

# Raised when the connection to the Redis server is lost.
class Redis::ConnectionLostError < Redis::ConnectionError
end
