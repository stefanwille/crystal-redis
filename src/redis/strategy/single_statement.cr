# Strategy for sending commands as individual requests and responses,
# which is the default case.
#

#:nodoc:
class Redis::Strategy::SingleStatement < Redis::Strategy::Base
  def initialize(connection)
    @connection = connection
  end

  def command(request : Request)
    @connection.send(request)
    @connection.receive
  end
end
