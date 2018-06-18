require "../src/redis"

# This program tests the command_timeout option.
#
# run: nc -l 7778

r = Redis.new(host: "localhost", port: 7778, command_timeout: 2.seconds)

r.set("test3", "a")
