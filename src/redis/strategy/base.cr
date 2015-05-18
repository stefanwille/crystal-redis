class Redis
  #:nodoc:
  module Strategy
    # Depending on the state that the Redis client is in,
    # requests and responses need to be treated differently.
    #
    # The behaviour is implemented using the Strategy design pattern,
    # and this is the base class for all strategies.
    #

    #:nodoc:
    abstract class Base
    end
  end
end

