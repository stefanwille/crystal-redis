class Redis::Client
  getter connection : Redis::Connection
  property strategy : Redis::Strategy::Base

  def initialize(host, port, unixsocket, password, database, sslcxt, dns_timeout, connect_timeout, command_timeout)
    @connection = Connection.new(host, port, unixsocket, sslcxt, dns_timeout, connect_timeout, command_timeout)
    @strategy = Redis::Strategy::SingleStatement.new(@connection)

    @strategy.command(["AUTH", password]) if password
    @strategy.command(["SELECT", database.to_s]) if database
  end

  def close
    @connection.close
  end
end
