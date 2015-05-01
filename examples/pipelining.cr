# This example shows Redis pipelining, as described in the documentation
# at http://redis.io/topics/pipelining
#

require "../src/redis"

puts "Connect to Redis"
redis = Redis.new

# Every command in the #pipelined method's block gets sent to Redis as one batch.
# Then Redis executes the commands and returns the responses.

puts "Running several commands pipelined"
redis.pipelined do |pipeline|
  pipeline.del("foo")
  pipeline.set("foo1", "first")
  pipeline.set("foo2", "second")
  pipeline.set("foo3", "third")
end

# Let's do a second batch:
#
# The responses of pipelined commands are futures.

puts "Running more commands pipelined, saving their futures"
future_1 = Redis::Future.new
future_2 = Redis::Future.new
future_3 = Redis::Future.new
future_4 = Redis::Future.new
responses = redis.pipelined do |pipeline|
  pipeline.set("foo4", "fourth")
  future_1 = pipeline.get("foo1") as Redis::Future
  future_2 = pipeline.get("foo2") as Redis::Future
  future_3 = pipeline.get("foo3") as Redis::Future
  future_4 = pipeline.get("foo4") as Redis::Future
end

puts "Responses: #{ responses }"

# The future's values become available after the pipelined block.

puts "Accessing the future values:"
puts future_1.value
puts future_2.value
puts future_3.value
puts future_4.value



