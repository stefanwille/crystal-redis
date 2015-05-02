# Definition of all Redis commands.
#
class Redis
  module Commands
    def echo(string)
      string_command(["ECHO", string.to_s])
    end

    def ping
      string_command(["PING"])
    end

    def set(key, value, ex = nil, px = nil, nx = nil, xx = nil)
      q = ["SET", key.to_s, value.to_s]
      q << "EX" << ex.to_s if ex
      q << "PX" << px.to_s if px
      q << "NX" << nx.to_s if nx
      q << "XX" << xx.to_s if xx
      string_or_nil_command(q)
    end

    def get(key)
      string_or_nil_command(["GET", key.to_s])
    end

    def quit
      string_command(["QUIT"])
    end

    def auth(password)
      string_command(["AUTH", password])
    end

    def select(database_number)
      string_command(["SELECT", database_number.to_s])
    end

    def rename(old_key, new_key)
      string_command(["RENAME", old_key.to_s, new_key.to_s])
    end

    def renamenx(old_key, new_key)
      integer_command(["RENAMENX", old_key.to_s, new_key.to_s])
    end

    def del(*keys)
      integer_command(concat(["DEL"], keys))
    end

    def sort(key, by = nil, limit = nil, get = nil : Array(RedisValue)?, order = "ASC", alpha = nil : Boolean?, store = nil)
      q = ["SORT", key.to_s]

      if by
        q << "BY" << by.to_s
      end

      if limit
        if limit.length != 2
          raise Error.new("limit must be an array of 2 elements (offset, count)")
        end
        offset, count = limit
        q << "LIMIT" << offset.to_s << count.to_s
      end

      if get
        get.each { |pattern| q << "GET" << pattern }
      end

      if order
        _order = order.upcase
        unless ["ASC", "DESC"].includes?(_order)
          raise Error.new("Bad order #{order}")
        end
        q << _order
      end

      if alpha
        q << "ALPHA"
      end

      if store
        q << "STORE" << store.to_s
      end

      string_array_or_integer_command(q)
    end

    def mget(*keys)
      string_array_command(concat(["MGET"], keys))
    end

    def mset(hash)
      q = ["MSET"] of RedisValue
      hash.each { |key, value| q << key.to_s << value.to_s }
      string_command(q)
    end

    def getset(key, value)
      string_or_nil_command(["GETSET", key.to_s, value])
    end

    def setex(key, value, expire_in_seconds)
      string_command(["SETEX", key.to_s, expire_in_seconds.to_s, value.to_s])
    end

    def psetex(key, value, expire_in_milis)
      string_command(["PSETEX", key.to_s, expire_in_milis.to_s, value.to_s])
    end

    def setnx(key, value)
      integer_command(["SETNX", key.to_s, value.to_s])
    end

    def msetnx(hash)
      q = ["MSETNX"] of RedisValue
      hash.each { |key, value| q << key.to_s << value }
      integer_command(q)
    end

    def incr(key)
      integer_command(["INCR", key.to_s])
    end

    def decr(key)
      integer_command(["DECR", key.to_s])
    end

    def incrby(key, value)
      integer_command(["INCRBY", key.to_s, value.to_s])
    end

    def incrbyfloat(key, value)
      string_command(["INCRBYFLOAT", key.to_s, value.to_s])
    end

    def decrby(key, value)
      integer_command(["DECRBY", key.to_s, value.to_s])
    end

    def append(key, value)
      integer_command(["APPEND", key.to_s, value.to_s])
    end

    def strlen(key)
      integer_command(["STRLEN", key.to_s])
    end

    def getrange(key, start_index, end_index)
      string_command(["GETRANGE", key.to_s, start_index.to_s, end_index.to_s])
    end

    def setrange(key, start_index, s)
      integer_command(["SETRANGE", key.to_s, start_index.to_s, s.to_s])
    end

    def bitcount(key, from, to)
      integer_command(["BITCOUNT", key.to_s, from.to_s, to.to_s])
    end

    def bitop(operation, key, *keys)
      integer_command(concat(["BITOP", operation.to_s, key.to_s], keys))
    end

    def getbit(key, index)
      integer_command(["GETBIT", key.to_s, index.to_s])
    end

    def setbit(key, index, value)
      integer_command(["SETBIT", key.to_s, index.to_s, value.to_s])
    end

    def bitpos(key, bit, start = nil, to = nil)
      q = ["BITPOS", key.to_s, bit.to_s] of RedisValue
      if start
        q << start.to_s
        if to
          q << to
        end
      end
      integer_command(q)
    end

    def dump(key)
      string_command(["DUMP", key.to_s])
    end

    def restore(key, ttl_in_milis : Int, serialized_value : String | Redis::Future)
      replace = nil
      q = ["RESTORE", key.to_s, ttl_in_milis.to_s, serialized_value] of RedisValue
      if replace
        q << replace.to_s
      end
      string_command(q)
    end

    def scan(cursor, match = nil, count = nil)
      q = ["SCAN", cursor.to_s]
      if match
        q << match
        if count
          q << count
        end
      end
      string_array_command(q)
    end

    def randomkey
      string_command(["RANDOMKEY"])
    end

    def exists(key)
      integer_command(["EXISTS", key.to_s])
    end

    def keys(pattern)
      string_array_command(["KEYS", pattern.to_s])
    end

    def rpush(key, *values)
      integer_command(concat(["RPUSH", key.to_s], values))
    end

    def lpush(key, *values)
      integer_command(concat(["LPUSH", key.to_s], values))
    end

    def lpushx(key, value)
      integer_command(["LPUSHX", key.to_s, value.to_s])
    end

    def rpushx(key, value)
      integer_command(["RPUSHX", key.to_s, value.to_s])
    end

    def lrem(key, count, value)
      integer_command(["LREM", key.to_s, count.to_s, value.to_s])
    end

    def llen(key)
      integer_command(["LLEN", key.to_s])
    end

    def lindex(key, index)
      string_or_nil_command(["LINDEX", key.to_s, index.to_s])
    end

    def lset(key, index, value)
      string_command(["LSET", key.to_s, index.to_s, value.to_s])
    end

    def lpop(key)
      string_or_nil_command(["LPOP", key.to_s])
    end

    def rpop(key)
      string_or_nil_command(["RPOP", key.to_s])
    end

    def linsert(key, where, pivot, value)
      integer_command(["LINSERT", key.to_s, where.to_s, pivot.to_s, value.to_s])
    end

    def lrange(key, from, to)
      string_array_command(["LRANGE", key.to_s, from.to_s, to.to_s])
    end

    def ltrim(key, start, stop)
      string_command(["LTRIM", key.to_s, start.to_s, stop.to_s])
    end

    def sadd(key, *values)
      integer_command(concat(["SADD", key.to_s], values))
    end

    def smembers(key)
      string_array_command(["SMEMBERS", key.to_s])
    end

    def sismember(key, value)
      integer_command(["SISMEMBER", key.to_s, value.to_s])
    end

    def srem(key, *values)
      integer_command(concat(["SREM", key.to_s], values))
    end

    def scard(key)
      integer_command(["SCARD", key.to_s])
    end

    def sdiff(*keys)
      string_array_command(concat(["SDIFF"], keys))
    end

    def sdiffstore(destination_key, *keys)
      integer_command(concat(["SDIFFSTORE", destination_key.to_s], keys))
    end

    def sinter(*keys)
      string_array_command(concat(["SINTER"], keys))
    end

    def sinterstore(destination_key, *keys)
      integer_command(concat(["SINTERSTORE", destination_key.to_s], keys))
    end

    def smove(source, destination, member)
      integer_command(["SMOVE", source.to_s, destination.to_s, member.to_s])
    end

    def spop(key, count = nil)
      q = ["SPOP", key.to_s]
      # Redis 3.0 should have the "count" argument, but doesn't yet.
      if count
        q << count.to_s
      end
      string_array_or_string_command(q)
    end

    def srandmember(key, count)
      string_array_command(["SRANDMEMBER", key.to_s, count.to_s])
    end

    def sscan(key, cursor, match = nil, count = nil)
          q = ["SSCAN", key.to_s, cursor.to_s]
      if match
        q << match
        if count
          q << count
        end
      end
      string_array_command(q)
    end

    def sunion(*keys)
      string_array_command(concat(["SUNION"], keys))
    end

    def sunionstore(destination_key, *keys)
      integer_command(concat(["SUNIONSTORE", destination_key.to_s], keys))
    end

    def blpop(keys, timeout_in_seconds)
      q = concat(["BLPOP"], keys)
      q << timeout_in_seconds.to_s
      array_or_nil_command(q)
    end

    def brpop(keys, timeout_in_seconds)
      q = concat(["BRPOP"], keys)
      q << timeout_in_seconds.to_s
      array_or_nil_command(q)
    end

    def rpoplpush(source, destination)
      string_or_nil_command(["RPOPLPUSH", source.to_s, destination.to_s])
    end

    def brpoplpush(source, destination, timeout_in_seconds)
      string_or_nil_command(["BRPOPLPUSH", source.to_s, destination.to_s, timeout_in_seconds.to_s])
    end

    def hset(key, field, value)
      integer_command(["HSET", key.to_s, field.to_s, value.to_s])
    end

    def hget(key, field)
      string_or_nil_command(["HGET", key.to_s, field.to_s])
    end

    def hgetall(key)
      string_array_command(["HGETALL", key.to_s])
    end

    def hdel(key, field)
      integer_command(["HDEL", key.to_s, field.to_s])
    end

    def hexists(key, field)
      integer_command(["HEXISTS", key.to_s, field.to_s])
    end

    def hincrby(key, field, delta)
      integer_command(["HINCRBY", key.to_s, field.to_s, delta.to_s])
    end

    def hincrbyfloat(key, field, delta)
      string_command(["HINCRBYFLOAT", key.to_s, field.to_s, delta.to_s])
    end

    def hkeys(key)
      string_array_command(["HKEYS", key.to_s])
    end

    def hlen(key)
      integer_command(["HLEN", key.to_s])
    end

    def hmget(key, *fields)
      string_array_command(concat(["HMGET", key.to_s], fields))
    end

    def hmset(key, hash)
      q = ["HMSET", key.to_s] of RedisValue
      hash.each { |field, value| q << field.to_s << value }
      string_command(q)
    end

    def hscan(key, cursor, match = nil, count = nil)
      q = ["HSCAN", key.to_s, cursor.to_s]
      if match
        q << match
        if count
          q << count
        end
      end
      string_array_command(q)
    end

    def hsetnx(key, field, value)
      integer_command(["HSETNX", key.to_s, field.to_s, value.to_s])
    end

    def hvals(key)
      string_array_command(["HVALS", key.to_s])
    end

    def zadd(key, *scores_and_members)
      if scores_and_members.length % 2 > 0
        raise Error.new("zadd expects an array of scores mapped to members")
      end

      integer_command(concat(["ZADD", key.to_s], scores_and_members))
    end

    def zrange(key, start = nil, stop = nil, with_scores = false)
      q = ["ZRANGE", key.to_s, start.to_s, stop.to_s]
      if with_scores
        q << "WITHSCORES"
      end
      string_array_command(q)
    end

    def zcard(key)
      integer_command(["ZCARD", key.to_s])
    end

    def zscore(key, member)
      string_or_nil_command(["ZSCORE", key.to_s, member.to_s])
    end

    def zcount(key, min, max)
      integer_command(["ZCOUNT", key.to_s, min.to_s, max.to_s])
    end

    def zlexcount(key, min, max)
      integer_command(["ZLEXCOUNT", key.to_s, min.to_s, max.to_s])
    end

    def zincrby(key, increment, member)
      string_command(["ZINCRBY", key.to_s, increment.to_s, member.to_s])
    end

    def zrem(key, member)
      integer_command(["ZREM", key.to_s, member.to_s])
    end

    def zrank(key, member)
      integer_or_nil_command(["ZRANK", key.to_s, member.to_s])
    end

    def zrevrank(key, member)
      integer_or_nil_command(["ZREVRANK", key.to_s, member.to_s])
    end

    def zinterstore(destination, keys : Array, weights = nil, aggregate = nil)
      numkeys = keys.length
      q = concat(["ZINTERSTORE", destination.to_s, numkeys.to_s], keys)
      if weights
        q << "WEIGHTS"
        concat(q, weights)
      end
      if aggregate
        q << "AGGREGATE" << aggregate.to_s
      end
      integer_command(q)
    end

    def zunionstore(destination, keys : Array, weights = nil, aggregate = nil)
      numkeys = keys.length
      q = concat(["ZUNIONSTORE", destination.to_s, numkeys.to_s], keys)
      if weights
        q << "WEIGHTS"
        concat(q, weights)
      end
      if aggregate
        q << "AGGREGATE" << aggregate.to_s
      end
      integer_command(q)
    end

    def zrangebylex(key, min, max, limit = nil)
      q = ["ZRANGEBYLEX", key.to_s, min.to_s, max.to_s]
      if limit
        q << "LIMIT" << limit[0].to_s << limit[1].to_s
      end
      string_array_command(q)
    end

    def zrangebyscore(key, min, max, limit = nil, with_scores = false)
      q = ["ZRANGEBYSCORE", key.to_s, min.to_s, max.to_s]
      if limit
        q << "LIMIT" << limit[0].to_s << limit[1].to_s
      end
      if with_scores
        q << "WITHSCORES"
      end
      string_array_command(q)
    end

    def zrevrange(key, start, stop, with_scores = false)
      q = ["ZREVRANGE", key.to_s, start.to_s, stop.to_s]
      if with_scores
        q << "WITHSCORES"
      end

      string_array_command(q)
    end

    def zrevrangebylex(key, min, max, limit = nil)
      q = ["ZREVRANGEBYLEX", key.to_s, min.to_s, max.to_s]
      if limit
        q << "LIMIT" << limit[0].to_s << limit[1].to_s
      end
      string_array_command(q)
    end

    def zrevrangebyscore(key, min, max, limit = nil, with_scores = false)
      q = ["ZREVRANGEBYSCORE", key.to_s, min.to_s, max.to_s]
      if limit
        q << "LIMIT" << limit[0].to_s << limit[1].to_s
      end
      if with_scores
        q << "WITHSCORES"
      end
      string_array_command(q)
    end

    def zremrangebylex(key, min, max)
      integer_command(["ZREMRANGEBYLEX", key.to_s, min.to_s, max.to_s])
    end

    def zremrangebyrank(key, start, stop)
      integer_command(["ZREMRANGEBYRANK", key.to_s, start.to_s, stop.to_s])
    end

    def zremrangebyscore(key, start, stop)
      integer_command(["ZREMRANGEBYSCORE", key.to_s, start.to_s, stop.to_s])
    end

    def zscan(key, cursor, match = nil, count = nil)
          q = ["ZSCAN", key.to_s, cursor.to_s]
      if match
        q << match
        if count
          q << count
        end
      end
      string_array_command(q)
    end

    def pfadd(key, *values)
      integer_command(concat(["PFADD", key.to_s], values))
    end

    def pfmerge(*keys)
      string_command(concat(["PFMERGE"], keys))
    end

    def pfcount(key)
      integer_command(["PFCOUNT", key.to_s])
    end

    def eval(script : String, keys = [] of RedisValue, args = [] of RedisValue)
      string_array_command(concat(["EVAL", script, keys.length.to_s], keys, args))
    end

    def evalsha(sha1, keys = [] of RedisValue, args = [] of RedisValue)
      string_array_command(concat(["EVALSHA", sha1.to_s, keys.length.to_s], keys, args))
    end

    def script_load(script : String)
      string_command(["SCRIPT", "LOAD", script])
    end

    def script_kill
      string_command(["SCRIPT", "KILL"])
    end

    def script_exists(sha1_array : Array(Reference))
      integer_array_command(concat(["SCRIPT", "EXISTS"], sha1_array))
    end

    def script_flush
      string_command(["SCRIPT", "FLUSH"])
    end

    def expire(key, seconds)
      integer_command(["EXPIRE", key.to_s, seconds.to_s])
    end

    def pexpire(key, milis)
      integer_command(["PEXPIRE", key.to_s, milis.to_s])
    end

    def expireat(key, unix_date)
      integer_command(["EXPIREAT", key.to_s, unix_date.to_s])
    end

    def pexpireat(key, unix_date_in_milis)
      integer_command(["PEXPIREAT", key.to_s, unix_date_in_milis.to_s])
    end

    def persist(key)
      integer_command(["PERSIST", key.to_s])
    end

    def ttl(key)
      integer_command(["TTL", key.to_s])
    end

    def pttl(key)
      integer_command(["PTTL", key.to_s])
    end

    def type(key)
      string_command(["TYPE", key.to_s])
    end

    # Subscribes to channels and enters a subscription loop, waiting for events.
    def subscribe(*channels, &callback_setup_block : Subscription ->)
      # Can be called only outside a subscription block
      if already_in_subscription_loop?
        raise Redis::Error.new("Must call subscribe without a subscription block when already inside a subscription loop")
      end

      subscription = Subscription.new
      # Allow the caller to populate the subscription with his callbacks.
      callback_setup_block.call(subscription)

      @strategy = Redis::Strategy::SubscriptionLoop.new(@connection, subscription)

      subscribe(*channels)
    end

    # Subscribes to more channels while already being in a subscription loop.
    def subscribe(*channels)
      # Can be called only inside a subscription block
      unless already_in_subscription_loop?
        raise Redis::Error.new("Must call subscribe with a subscription block")
      end

      void_command(concat(["SUBSCRIBE"], channels))
    end

    # Subscribes to channel patterns and enters a subscription loop, waiting for events.
    def psubscribe(*channel_patterns, &callback_setup_block : Subscription ->)
      # Can be called only outside a subscription block
      if already_in_subscription_loop?
        raise Redis::Error.new("Must call psubscribe without a subscription block when inside a subscription loop")
      end

      subscription = Subscription.new
      # Allow the caller to populate the subscription with his callbacks.
      callback_setup_block.call(subscription)

      @strategy = Redis::Strategy::SubscriptionLoop.new(@connection, subscription)

      psubscribe(*channel_patterns)
    end

    # Subscribes to more channel patterns while already being in a subscription loop.
    def psubscribe(*channel_patterns)
      # Can be called only inside a subscription block
      unless already_in_subscription_loop?
        raise Redis::Error.new("Must call psubscribe with a subscription block")
      end

      void_command(concat(["PSUBSCRIBE"], channel_patterns))
    end

    private def already_in_subscription_loop?
      @strategy.is_a? Redis::Strategy::SubscriptionLoop
    end

    def unsubscribe(*channels)
      void_command(concat(["UNSUBSCRIBE"], channels))
    end

    def punsubscribe(*channel_patterns)
      void_command(concat(["PUNSUBSCRIBE"], channel_patterns))
    end

    def publish(channel, message)
      integer_command(["PUBLISH", channel.to_s, message.to_s])
    end

    def watch(*keys)
      string_command(concat(["WATCH"], keys))
    end

    def unwatch
      string_command(["UNWATCH"])
    end

    # Concatenates the source array to the destination array.
    # Is there a better way?
    private def concat(destination : Array(RedisValue), source)
      source.each { |value| destination << value.to_s }
      destination
    end

    # Concatenates the source arrays to the destination array.
    # Is there a better way?
    private def concat(destination : Array(RedisValue), source1, source2)
      concat(destination, source1)
      concat(destination, source2)
      destination
    end
  end
end
