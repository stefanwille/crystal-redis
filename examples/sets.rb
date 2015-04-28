# This example shows a few commands for the Redis SET datatype.
#

require "../src/redis"

redis = Redis.new

redis.del "foo-tags"
redis.del "bar-tags"

puts
puts "create a set of tags on foo-tags"

redis.sadd "foo-tags", "one"
redis.sadd "foo-tags", "two"
redis.sadd "foo-tags", "three"

puts
puts "create a set of tags on bar-tags"

redis.sadd "bar-tags", "three"
redis.sadd "bar-tags", "four"
redis.sadd "bar-tags", "five"

puts
puts "foo-tags"

puts redis.smembers("foo-tags")

puts
puts "bar-tags"

puts redis.smembers("bar-tags")

puts
puts "intersection of foo-tags and bar-tags"

puts redis.sinter("foo-tags", "bar-tags")

