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
