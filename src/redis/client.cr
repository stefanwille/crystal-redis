class Redis::Client
  getter connection : Redis::Connection
  property strategy : Redis::Strategy::Base

  def initialize(@connection : Redis::Connection, @strategy : Redis::Strategy::Base)
  end
end
