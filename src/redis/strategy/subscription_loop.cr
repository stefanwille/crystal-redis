# :nodoc:
#
# Strategy for sending commands while the client is subscribed to at least one channel.
class Redis::Strategy::SubscriptionLoop < Redis::Strategy::Base
  def initialize(connection, subscription)
    @connection = connection
    @subscription = subscription
    @entered_loop = false
  end

  def command(request : Request)
    @connection.send(request)

    # Enter the message reception loop only once.
    if @entered_loop
      return
    else
      enter_message_reception_loop
    end
  end

  private def enter_message_reception_loop
    @entered_loop = true
    loop do
      response = @connection.receive
      break if !dispatch_response(response)
    end
  end

  private def dispatch_response(response)
    result = (response as Array(RedisValue)).not_nil!
    message_type = result[0] as String
    case message_type
    when "subscribe"
      channel = result[1] as String
      subscriptions = result[2] as Int64
      @subscription.subscribe_callback.call(channel, subscriptions)
      subscriptions > 0
    when "psubscribe"
      channel_pattern = result[1] as String
      subscriptions = result[2] as Int64
      @subscription.psubscribe_callback.call(channel_pattern, subscriptions)
      subscriptions > 0
    when "message"
      channel = result[1] as String
      message = result[2] as String
      @subscription.message_callback.call(channel, message)
      true
    when "pmessage"
      channel_pattern = result[1] as String
      channel = result[2] as String
      message = result[3] as String
      @subscription.pmessage_callback.call(channel_pattern, channel, message)
      true
    when "unsubscribe"
      channel = result[1] as String
      subscriptions = result[2] as Int64
      @subscription.unsubscribe_callback.call(channel, subscriptions)
      subscriptions > 0
    when "punsubscribe"
      channel_pattern = result[1] as String
      subscriptions = result[2] as Int64
      @subscription.punsubscribe_callback.call(channel_pattern, subscriptions)
      subscriptions > 0
    else
      raise Redis::Error.new("Unknown message_type #{message_type}")
    end
  end
end
