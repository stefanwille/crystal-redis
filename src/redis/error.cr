# Exception for errors raised by this shard.
class Redis::Error < Exception
end

# Raised when connecting to the Redis server is not possible.
class Redis::CannotConnectError < Redis::Error
end

# Errors that occur on a connection.
class Redis::ConnectionError < Redis::Error
end

# The connection to the Redis server got lost,
# possibly because the Redis server died, or because it decided to close the connection.
class Redis::DisconnectedError < Redis::ConnectionError
end
