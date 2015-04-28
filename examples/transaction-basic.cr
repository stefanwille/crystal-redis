# This example shows a Redis transaction, as describe in the documentation
# at http://redis.io/topics/transactions
#

require "../src/redis"

puts "Connect to Redis"
redis = Redis.new

# Every command in the #transaction method's block gets sent to Redis as one batch.
# Then Redis executes the commands and returns the responses.

puts "Running several commands in a transaction"
redis.transaction do
  redis.del("foo")
  redis.set("foo1", "first")
  redis.set("foo2", "second")
  redis.set("foo3", "third")
end

puts "Current value of foo1: " + redis.get("foo1") as String
