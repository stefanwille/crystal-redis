# The Redis client API in such a form that all command methods
# don't return responses but Futures.
#
class FutureBasedAPI
  # Most client API methods are defined in this Redis::module.
  include Redis::Commands

  def initialize(@strategy)
  end

  # Abort a current transaction.
  # Only valid in the context of transaction.
  def discard
    @strategy.discard
  end

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

  # Executes a Redis command and returns a Future.
  def command(request : Request)
    @strategy.command(request) as Redis::Future
  end
end
