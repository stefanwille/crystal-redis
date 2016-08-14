# :nodoc:
#
# Strategy for sending commands while the client is subscribed to at least one channel.
class Redis::Strategy::SubscriptionLoop < Redis::Strategy::Base
  def initialize(connection : Connection, subscription : Subscription)
    @connection = connection
    @subscription = subscription
    @entered_loop = false
  end

  def command(request : Request)
    validate_command(request)
    @connection.send(request)

    # Enter the message reception loop only once.
    if @entered_loop
      return
    else
      enter_message_reception_loop
    end
  end

  ALLOWED_COMMANDS = ["SUBSCRIBE", "PSUBSCRIBE", "UNSUBSCRIBE", "PUNSUBSCRIBE", "PING", "QUIT"]

  private def validate_command(request : Request)
    return if ALLOWED_COMMANDS.includes?(request[0])
    raise Redis::Error.new("Command #{request[0]} not allowed in the context of a subscribed connection")
  end

  private def enter_message_reception_loop
    @entered_loop = true
    loop do
      received_message = @connection.receive
      break if !dispatch_received_message(received_message)
    end
  end

  private def dispatch_received_message(received_message_uncasted)
    received_message = (received_message_uncasted.as(Array(RedisValue))).not_nil!
    message_type = received_message[0].as(String)
    case message_type
    when "subscribe"
      channel = received_message[1].as(String)
      subscriptions = received_message[2].as(Int64)
      @subscription.subscribe_callback.try &.call(channel, subscriptions)
      subscriptions > 0
    when "psubscribe"
      channel_pattern = received_message[1].as(String)
      subscriptions = received_message[2].as(Int64)
      @subscription.psubscribe_callback.try &.call(channel_pattern, subscriptions)
      subscriptions > 0
    when "message"
      channel = received_message[1].as(String)
      message = received_message[2].as(String)
      @subscription.message_callback.try &.call(channel, message)
      true
    when "pmessage"
      channel_pattern = received_message[1].as(String)
      channel = received_message[2].as(String)
      message = received_message[3].as(String)
      @subscription.pmessage_callback.try &.call(channel_pattern, channel, message)
      true
    when "unsubscribe"
      channel = received_message[1].as(String)
      subscriptions = received_message[2].as(Int64)
      @subscription.unsubscribe_callback.try &.call(channel, subscriptions)
      subscriptions > 0
    when "punsubscribe"
      channel_pattern = received_message[1].as(String)
      subscriptions = received_message[2].as(Int64)
      @subscription.punsubscribe_callback.try &.call(channel_pattern, subscriptions)
      subscriptions > 0
    else
      raise Redis::Error.new("Unknown message_type #{message_type}")
    end
  end
end
