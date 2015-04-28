# This example shows a Redis transaction, as describe in the documentation
# at http://redis.io/topics/transactions
#

require "../src/redis"

puts "Connect to Redis"
redis = Redis.new

# Commands sent in a transaction return futures.

puts "Running several commands in transaction, saving their futures"
future_1 = Redis::Future.new
future_2 = Redis::Future.new
redis.multi do
  redis.set("foo1", "A")
  redis.set("foo2", "B")
  future_1 = redis.get("foo1") as Redis::Future
  future_2 = redis.get("foo2") as Redis::Future
end

# The future's values become available after the transaction block.

puts "Accessing the future's values:"
puts future_1.value
puts future_2.value
