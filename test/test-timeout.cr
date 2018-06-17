require "../src/redis"

# This program tests command timeout.
#
# run: nc -l 7778

r = Redis.new(host: "localhost", port: 7778, timeout: 1.second)

r.set("test3", "a")
