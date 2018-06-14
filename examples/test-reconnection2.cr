require "../src/redis"

# run: redis-server --port 7777 --timeout 5

r = Redis.new(host: "localhost", port: 7777)

r.set("test2", "a")
p r.get("test2")

# exceed timeout of redis connection
p "wait for 7 seconds"
sleep 7

p r.get("test2")
