require "../src/redis"

# This program tests auto reconnection.
#
# run: redis-server --port 7777 --timeout 5
# start/stop server in the middle

r = Redis.new(host: "localhost", port: 7777)

loop do
  begin
    r.set("test1", "a")
    p r.get("test1")
  rescue ex : Redis::Error
    p ex
  end

  sleep 1.0
end
