# Models a subscription to one or more publish/subscribe channels.
#
# The caller sets callbacks on this object that the Redis client will
# trigger for the matching events.
class Redis::Subscription
  # :nodoc:
  getter :subscribe_callback
  # :nodoc:
  getter :psubscribe_callback
  # :nodoc:
  getter :message_callback
  # :nodoc:
  getter :pmessage_callback
  # :nodoc:
  getter :unsubscribe_callback
  # :nodoc:
  getter :punsubscribe_callback

  # Sets the 'subscribe' callback.
  def subscribe(&@subscribe_callback : String, Int64 ->)
  end

  # Sets the 'psubscribe' callback.
  def psubscribe(&@psubscribe_callback : String, Int64 ->)
  end

  # Sets the 'message' callback.
  def message(&@message_callback : String, String ->)
  end

  # Sets the 'pmessage' callback.
  def pmessage(&@pmessage_callback : String, String, String ->)
  end

  # Sets the 'unsubscribe' callback.
  def unsubscribe(&@unsubscribe_callback : String, Int64 ->)
  end

  # Sets the 'punsubscribe' callback.
  def punsubscribe(&@punsubscribe_callback : String, Int64 ->)
  end
end
