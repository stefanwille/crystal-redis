# This example demonstrates the INCR and DECR commands.

require "../src/redis"

redis = Redis.new

redis.del "counter"

puts "incr"
puts redis.incr("counter")
puts redis.incr("counter")
puts redis.incr("counter")

puts
puts "decr"
puts redis.decr("counter")
puts redis.decr("counter")
puts redis.decr("counter")
