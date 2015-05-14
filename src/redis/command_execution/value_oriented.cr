class Redis
  module CommandExecution
    # Command execution methods that return real values, not futures.
    #
    module ValueOriented
      # Executes a Redis command and casts it to the correct type.
      # This is an internal method.
      def integer_command(request : Request)
        command(request) as Int64
      end

      # Executes a Redis command and casts it to the correct type.
      # This is an internal method.
      def integer_or_nil_command(request : Request)
        command(request) as Int64?
      end

      # Executes a Redis command and casts it to the correct type.
      # This is an internal method.
      def integer_array_command(request : Request)
        command(request) as Array(RedisValue)
      end

      # Executes a Redis command and casts it to the correct type.
      # This is an internal method.
      def string_command(request : Request)
        command(request) as String
      end

      # Executes a Redis command and casts the response to the correct type.
      # This is an internal method.
      def string_or_nil_command(request : Request)
        command(request) as String?
      end

      # Executes a Redis command and casts the response to the correct type.
      # This is an internal method.
      def string_array_command(request : Request)
        command(request) as Array(RedisValue)
      end

      # Executes a Redis command and casts the response to the correct type.
      # This is an internal method.
      def string_array_or_integer_command(request : Request)
        command(request) as Array(RedisValue) | Int64
      end

      # Executes a Redis command and casts the response to the correct type.
      # This is an internal method.
      def string_array_or_string_command(request : Request)
        command(request) as Array(RedisValue) | String
      end

      # Executes a Redis command and casts the response to the correct type.
      # This is an internal method.
      def string_array_or_string_or_nil_command(request : Request)
        command(request) as Array(RedisValue) | String?
      end

      # Executes a Redis command and casts the response to the correct type.
      # This is an internal method.
      def array_or_nil_command(request : Request)
        command(request) as Array(RedisValue)?
      end

      # Executes a Redis command that has no relevant response.
      # This is an internal method.
      def void_command(request : Request)
        command(request)
      end
    end
  end
end
