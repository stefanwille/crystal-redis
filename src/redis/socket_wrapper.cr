# Wraps an open socket connection.
#
# The purpose is to be able to convert all exceptions to Redis:Error's.
struct Redis::SocketWrapper
  def initialize(@socket : TCPSocket | UNIXSocket | OpenSSL::SSL::Socket::Client)
    @connected = true
  end

  def self.new
    self.new(yield)
  rescue ex : IO::TimeoutError | Socket::Error | OpenSSL::Error
    raise Redis::CannotConnectError.new("#{ex.class}: #{ex.message}")
  end

  macro method_missing(call)
    catch_errors { @socket.{{call}} }
  end

  private def catch_errors
    yield
  rescue ex : IO::Error | OpenSSL::Error
    raise Redis::ConnectionLostError.new("#{ex.class}: #{ex.message}")
  rescue ex : IO::TimeoutError
    raise Redis::CommandTimeoutError.new("Command timed out")
  end

  def close
    if @connected
      @connected = false
      @socket.close
    end
  rescue Socket::Error
  end
end
