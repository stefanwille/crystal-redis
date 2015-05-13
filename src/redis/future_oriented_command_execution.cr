# Command execution methods that don't return responses but Futures.
#
module Redis::FutureOrientedCommandExecution
  # Executes a Redis command and returns a Future.
  def integer_command(request : Request)
    command(request)
  end

  # Executes a Redis command and returns a Future.
  def integer_or_nil_command(request : Request)
    command(request)
  end

  # Executes a Redis command and returns a Future.
  def integer_array_command(request : Request)
    command(request)
  end

  # Executes a Redis command and returns a Future.
  def string_command(request : Request)
    command(request)
  end

  # Executes a Redis command and returns a Future.
  def string_or_nil_command(request : Request)
    command(request)
  end

  # Executes a Redis command and returns a Future.
  def string_array_command(request : Request)
    command(request)
  end

  # Executes a Redis command and returns a Future.
  def string_array_or_integer_command(request : Request)
    command(request)
  end

  # Executes a Redis command and returns a Future.
  def string_array_or_string_command(request : Request)
    command(request)
  end

  # Executes a Redis command and returns a Future.
  def array_or_nil_command(request : Request)
    command(request)
  end

  # Executes a Redis command and returns a Future.
  def void_command(request : Request)
    command(request)
  end
end
