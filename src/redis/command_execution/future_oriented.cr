class Redis
  # This module contains mixins for the execution of Redis commands.

  # :nodoc:
  module CommandExecution
    # Command execution methods that don't return Redis values but Futures.

    # :nodoc:
    module FutureOriented
      # Executes a Redis command and returns a Future.
      def integer_command(request : Request) : Redis::Future
        command(request)
      end

      # Executes a Redis command and returns a Future.
      def integer_or_nil_command(request : Request) : Redis::Future
        command(request)
      end

      # Executes a Redis command and returns a Future.
      def integer_array_command(request : Request) : Redis::Future
        command(request)
      end

      # Executes a Redis command and returns a Future.
      def string_command(request : Request) : Redis::Future
        command(request)
      end

      # Executes a Redis command and returns a Future.
      def string_or_nil_command(request : Request) : Redis::Future
        command(request)
      end

      # Executes a Redis command and returns a Future.
      def string_array_command(request : Request) : Redis::Future
        command(request)
      end

      # Executes a Redis command and returns a Future.
      def string_array_or_integer_command(request : Request) : Redis::Future
        command(request)
      end

      # Executes a Redis command and returns a Future.
      def string_array_or_string_command(request : Request) : Redis::Future
        command(request)
      end

      # Executes a Redis command and returns a Future.
      def string_array_or_string_or_nil_command(request : Request) : Redis::Future
        command(request)
      end

      # Executes a Redis command and returns a Future.
      def array_or_nil_command(request : Request) : Redis::Future
        command(request)
      end

      # Executes a Redis command and returns a Future.
      def void_command(request : Request) : Redis::Future
        command(request)
      end
    end
  end
end
