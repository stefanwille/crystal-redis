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
responses = redis.multi do |multi|
  multi.set("foo1", "A")
  multi.set("foo2", "B")
  future_1 = multi.get("foo1")
  future_2 = multi.get("foo2")
end

puts "Responses: #{ responses }"

# The future's values become available after the transaction block.

puts "Accessing the future's values:"
puts future_1.value
puts future_2.value
