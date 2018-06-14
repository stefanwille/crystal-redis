struct SocketWrapper
  def initialize(@socket : TCPSocket | UNIXSocket | OpenSSL::SSL::Socket::Client)
    @connected = true
  end

  def self.new
    self.new(yield)
  rescue ex : IO::Timeout | Errno | Socket::Error | OpenSSL::Error
    raise Redis::CannotConnectError.new("#{ex.class}: #{ex.message}")
  end

  macro method_missing(call)
    catch_errors { @socket.{{call}} }
  end

  private def catch_errors
    yield
  rescue ex : Errno | IO::Error | IO::Timeout | OpenSSL::Error
    raise Redis::ConnectionError.new("#{ex.class}: #{ex.message}")
  end

  def close
    if @connected
      @connected = false
      @socket.close
    end
  rescue Errno
  end
end
