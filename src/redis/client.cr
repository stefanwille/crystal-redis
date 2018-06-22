class Redis::Client
  getter connection : Redis::Connection
  property strategy : Redis::Strategy::Base

  def initialize(@connection : Redis::Connection, password, database)
    @strategy = Redis::Strategy::SingleStatement.new(@connection)

    @strategy.command(["AUTH", password]) if password
    @strategy.command(["SELECT", database.to_s]) if database
  end

  def close
    @connection.close
  end
end
