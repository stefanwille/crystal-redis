# Futures are handles for values that will become available at a later point in time.
#
# The API methods Redis#pipelined and Redis#multi make commands return futures instead of actual values.
#
# See this [example](https://github.com/stefanwille/crystal-redis-examples/blob/master/src/pipelining.cr).
class Redis::Future
  @value : Redis::RedisValue

  def initialize
    @value
    @ready = false
  end

  def value
    if @ready
      @value
    else
      raise Redis::Error.new "Future value not ready yet"
    end
  end

  def value=(new_value)
    @value = new_value
    @ready = true
  end
end
