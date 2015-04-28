require "../../src/redis"

redis = Redis.new
puts "Connected to Redis - subscribing to mychannel and waiting for messages from publish.cr"
redis.subscribe("mychannel") do |on|
  on.message do |channel, message|
    puts "Received message: #{message}"
  end
end
