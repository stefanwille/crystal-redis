require "../src/redis"

# This program tests auto reconnection with pipelined commands.
#
# run: redis-server --port 7777 --timeout 5
# start/stop server in the middle

r = Redis.new(host: "localhost", port: 7777)

loop do
  begin
    r.pipelined do |pipeline|
      pipeline.set("test1", "first")
      pipeline.set("test2", "second")
    end
    puts "Sent the pipelined commands"
  rescue ex : Redis::Error
    p ex
  end

  sleep 1.0
end
