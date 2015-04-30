class FutureClient
  include Redis::Commands

  def initialize(@strategy)
  end

  def integer_command(request : Request)
    command(request)
  end

  def integer_or_nil_command(request : Request)
    command(request)
  end

  def integer_array_command(request : Request)
    command(request)
  end

  def string_command(request : Request)
    command(request)
  end

  def string_or_nil_command(request : Request)
    command(request)
  end

  def string_array_command(request : Request)
    command(request)
  end

  def string_array_or_integer_command(request : Request)
    command(request)
  end

  def string_array_or_string_command(request : Request)
    command(request)
  end

  def array_or_nil_command(request : Request)
    command(request)
  end

  def void_command(request : Request)
    command(request)
  end

  def command(request : Request)
    @strategy.command(request) as Redis::Future
  end

  def discard
    @strategy.discard
  end
end
