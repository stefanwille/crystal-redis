# :nodoc:
#
# Strategy for sending commands as individual request/response pairs,
# which is the default case.
class Redis::Strategy::SingleStatement < Redis::Strategy::Base
  def initialize(connection : Connection)
    @connection = connection
  end

  def command(request : Request)
    @connection.send(request)
    @connection.receive
  end
end
