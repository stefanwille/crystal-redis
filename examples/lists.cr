require "../src/redis"

redis = Redis.new

redis.del "logs"

puts

puts "pushing log messages into a LIST"
redis.rpush "logs", "some log message"
redis.rpush "logs", "another log message"
redis.rpush "logs", "yet another log message"
redis.rpush "logs", "also another log message"

puts
puts "contents of logs LIST"

puts redis.lrange("logs", 0, -1)

puts
puts "Trim logs LIST to last 2 elements(easy circular buffer)"

redis.ltrim("logs", -2, -1)

puts redis.lrange("logs", 0, -1)
