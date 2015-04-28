# This basic example shows:
#  - how to connect to the Redis server
#  - how to delete a key
#  - how to set a key's value
#  - how to get a key's value

require "../src/redis"

puts "Connect to Redis"
redis = Redis.new

puts "Delete foo"
redis.del("foo")

puts "Set foo to \"bar\""
redis.set("foo", "bar")

puts "Value of foo is:"
puts redis.get("foo")
