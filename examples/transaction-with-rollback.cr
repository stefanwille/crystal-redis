# This example shows a Redis transaction, as describe in the documentation
# at http://redis.io/topics/transactions
#

require "../src/redis"

puts "Connect to Redis"
redis = Redis.new
puts

# We want to rollback a transaction.
# The way to do this is in Redis is to send a DISCARD command.

puts "Initializing foo"
redis.set("foo", "the old value")

results = redis.multi do
  puts "Updating foo in transaction"
  redis.set("foo", "the new value")

  puts "DISCARDing the transaction"
  redis.discard
end
puts "Current value of foo: " + redis.get("foo") as String

