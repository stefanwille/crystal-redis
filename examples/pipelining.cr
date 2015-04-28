# This example shows Redis pipelining, as described in the documentation
# at http://redis.io/topics/pipelining
#

require "../src/redis"

puts "Connect to Redis"
redis = Redis.new

# Every command in the #pipelined method's block gets sent to Redis as one batch.
# Then Redis executes the commands and returns the responses.

puts "Running several commands pipelined"
redis.pipelined do
  redis.del("foo")
  redis.set("foo1", "first")
  redis.set("foo2", "second")
  redis.set("foo3", "third")
end

# Let's do a second batch:
#
# The responses of pipelined commands are futures.

puts "Running more commands pipelined, saving their futures"
future_1 = Redis::Future.new
future_2 = Redis::Future.new
future_3 = Redis::Future.new
future_4 = Redis::Future.new
redis.pipelined do
  redis.set("foo4", "fourth")
  future_1 = redis.get("foo1") as Redis::Future
  future_2 = redis.get("foo2") as Redis::Future
  future_3 = redis.get("foo3") as Redis::Future
  future_4 = redis.get("foo4") as Redis::Future
end

# The future's values become available after the pipelined block.

puts "Accessing the future's values:"
puts future_1.value
puts future_2.value
puts future_3.value
puts future_4.value



