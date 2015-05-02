require "socket"

# A connection to a Redis instance.
#
class Redis::Connection
  def initialize(host, port, unixsocket)
    if unixsocket
      @socket = UNIXSocket.new(unixsocket)
    else
      @socket = TCPSocket.new(host, port)
    end
    @io = BufferedIO.new @socket
    @connected = true
  end

  def finalize
    close
  end

  def close
    if @connected
      @socket.close
      @connected = false
    end
  end

  def send(request : Request)
    queue(request)
    flush
  end

  def queue(request : Request)
    @io << marshal(request)
  end

  def flush
    @io.flush
  end

  def marshal(arg : Int)
    ":#{arg}\r\n"
  end

  def marshal(arg : String)
    "$#{arg.size}\r\n#{arg}\r\n"
  end

  def marshal(arg : Array(RedisValue))
    result = StringIO.new
    result << "*#{arg.length}\r\n"
    arg.each { |element| result << marshal(element) }
    result.to_s
  end

  def marshal(arg : Nil)
    "$-1\r\n"
  end

  # Receives n responses with the content "QUEUED".
  # This method exists to prevent many small read calls.
  #
  def receive_queued_responses(n)
    bytes_per_queued_responses = "+QUEUED\r\n".size
    nbytes = n * bytes_per_queued_responses
    @io.read(nbytes)
  end

  def receive
    type = @io.read_char
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

      slice = Slice(UInt8).new(length)
      @io.read(slice)
      bulk_string = String.new(slice)
      crlf = @io.read(2)
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
      raise Redis::Error.new("Cannot parse response with type #{type}: #{receive_line.inspect}")
    end
  end

  def receive_line
    line = @io.gets
    unless line
      raise Redis::Error.new("Disconnected")
    end
    line[0, line.length-2]
  end
end
