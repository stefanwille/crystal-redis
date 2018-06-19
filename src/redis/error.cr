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

# Raised when the `command_timeout` option triggers - a command took too long because the Redis-server is blocked by another command or by a dump.
class Redis::CommandTimeoutError < Redis::Error
end

# Raised when no free connection became available in the pool within a certain time.
class Redis::PoolTimeoutError < Redis::Error
end
