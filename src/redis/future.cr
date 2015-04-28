# A future, as returned by Redis#pipelined or Redis#transaction.
#
# Futures are handles for values that will become available at a later point in time.
# See https://github.com/stefanwille/crystal-redis/blob/master/examples/pipelining.cr
# for an example.
class Redis::Future
  def initialize
    @value
    @ready = false
  end

  def value
    if @ready
      @value
    else
      raise Redis::Error.new "Redis: Future value not ready yet"
    end
  end

  def value=(new_value)
    @value = new_value
    @ready = true
  end
end
