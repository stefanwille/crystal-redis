# Exception for errors that Redis returns.
class Redis::Error < Exception
end

class Redis::ConnectionError < Redis::Error
end

class Redis::CannotConnectError < Redis::ConnectionError
end
