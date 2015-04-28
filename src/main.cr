require "./**"

redis = Redis.new

s = redis.echo("yeah")
puts s.length

future = Redis::Future.new
redis.pipelined do |pipeline|
  future = pipeline.echo("hello")
end

puts future.value


