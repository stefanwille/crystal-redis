require "socket"
require "openssl"

# A connection to a Redis instance.

# :nodoc:
class Redis::Connection
  def initialize(host, port, unixsocket, ssl_context, dns_timeout = nil, connect_timeout = nil, command_timeout = nil)
    if unixsocket
      @socket = Redis::SocketWrapper.new do
        socket = UNIXSocket.new(unixsocket)
        if command_timeout
          socket.read_timeout = command_timeout
          socket.write_timeout = command_timeout
        end
        socket
      end
    elsif ssl_context
      @socket = Redis::SocketWrapper.new do
        tcpsocket = TCPSocket.new(host, port, dns_timeout: dns_timeout, connect_timeout: connect_timeout)
        if command_timeout
          tcpsocket.read_timeout = command_timeout
          tcpsocket.write_timeout = command_timeout
        end
        tcpsocket.sync = false
        OpenSSL::SSL::Socket::Client.new(tcpsocket, ssl_context)
      end
    else
      @socket = Redis::SocketWrapper.new do
        tcpsocket = TCPSocket.new(host, port, dns_timeout: dns_timeout, connect_timeout: connect_timeout)
        if command_timeout
          tcpsocket.read_timeout = command_timeout
          tcpsocket.write_timeout = command_timeout
        end
        tcpsocket.sync = false
        tcpsocket
      end
    end
  end

  def finalize
    close
  end

  def close
    @socket.close
  end

  def send(request : Request)
    queue(request)
    flush
  end

  def queue(request : Request)
    marshal(request, @socket)
  end

  def flush
    @socket.flush
  end

  def marshal(arg : Int, io)
    io << ":" << arg << "\r\n"
  end

  def marshal(arg : String, io)
    io << "$" << arg.bytesize << "\r\n" << arg << "\r\n"
  end

  def marshal(arg : Array(RedisValue), io)
    io << "*" << arg.size << "\r\n"
    arg.each do |element|
      marshal(element, io)
    end
  end

  def marshal(arg : Nil, io)
    io << "$-1\r\n"
  end

  # Receives n responses with the expected content "QUEUED".
  # This method exists to prevent many small read calls.
  #
  def receive_queued_responses(n)
    if n == 0
      return
    end
    bytes_per_queued_responses = "+QUEUED\r\n".bytesize
    nbytes = n * bytes_per_queued_responses
    @socket.skip(nbytes)
  end

  def receive
    type = @socket.read_char
    line = receive_line

    case type
    when '-'
      # Error
      raise Redis::Error.new(line)
    when ':'
      # Integer
      line.to_i64
    when '$'
      # Bulk string
      length = line.to_i

      # The "Null bulk string" aka nil
      return nil if length == -1

      bulk_string = String.new(length) do |buffer|
        @socket.read_fully(Slice.new(buffer, length))
        {length, 0}
      end
      # Ignore CR/LF
      @socket.skip(2)
      bulk_string
    when '+'
      # Simple string
      line
    when '*'
      # Array
      length = line.to_i
      result = [] of RedisValue
      length.times do
        result << receive
      end
      result
    when nil
      raise Redis::Error.new("Received nil type string")
    else
      raise Redis::Error.new("Cannot parse response with type #{type}: #{line.inspect}")
    end
  end

  def receive_line
    line = @socket.gets(chomp: false)
    unless line
      # The connection to the Redis server got lost,
      # possibly because the Redis server died, or because it decided to close the connection.
      raise Redis::ConnectionLostError.new("The redis server closed the connection")
    end
    line.byte_slice(0, line.bytesize - 2)
  end
end
