require "../src/redis"

# This program tests auto reconnection for subscribe.
#
# run: redis-server --port 7777 --timeout 5
# start/stop server in the middle

r = Redis::PooledClient.new(host: "localhost", port: 7777)

spawn do
  i = 0
  loop do
    p "publish #{i}"
    r.publish("mychannel", i.to_s) rescue nil
    i += 1
    if i > 10
      r.publish("mychannel", 'q') rescue nil
    end
    sleep 1.0
  end
end

r.subscribe("mychannel") do |on|
  on.message do |channel, message|
    puts "Received message: #{message}"
    if message == "q"
      p "Unsubscribe"
      r.unsubscribe("mychannel")
    end
  end
end
