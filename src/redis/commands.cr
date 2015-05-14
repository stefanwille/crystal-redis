class Redis
  # Definition of all Redis commands except pipelining and transactions.
  #
  module Commands

    # Returns the given message.
    def echo(message)
      string_command(["ECHO", message.to_s])
    end

    # Returns PONG. This command is often used to test if a connection is still alive, or to measure latency.
    def ping
      string_command(["PING"])
    end

    # Set key to hold the string value. If key already holds a value, it is overwritten, regardless of its type. Any previous time to live associated with the key is discarded on successful SET operation.
    #
    # **Options**:
    #
    # * Starting with Redis 2.6.12 SET supports a set of options that modify its behavior:
    # * ex seconds -- Set the specified expire time, in seconds.
    # * px milliseconds -- Set the specified expire time, in milliseconds.
    # * nx -- Only set the key if it does not already exist.
    # * xx -- Only set the key if it already exist.
    #
    # **Return value**:
    # * OK if SET was executed correctly.
    # * Null reply: nil is returned if the SET operation was not performed because the user specified the NX or XX option but the condition was not met.
    def set(key, value, ex = nil, px = nil, nx = nil, xx = nil)
      q = ["SET", key.to_s, value.to_s]
      q << "EX" << ex.to_s if ex
      q << "PX" << px.to_s if px
      q << "NX" << nx.to_s if nx
      q << "XX" << xx.to_s if xx
      string_or_nil_command(q)
    end

    # Get the value of key.
    #
    # **Return value**: a String or nil
    def get(key)
      string_or_nil_command(["GET", key.to_s])
    end

    # Ask the server to close the connection. The connection is closed as soon as all pending replies have been written to the client.
    #
    # **Return value**: "OK"
    def quit
      string_command(["QUIT"])
    end

    # Request for authentication in a password-protected Redis server.
    #
    # **Return value**: "OK"
    def auth(password)
      string_command(["AUTH", password])
    end

    # Select the DB with having the specified zero-based numeric index.
    #
    # **Return value**: "OK"
    def select(database_number)
      string_command(["SELECT", database_number.to_s])
    end

    # Renames old_key to newkey.
    #
    # **Return value**: "OK"
    def rename(old_key, new_key)
      string_command(["RENAME", old_key.to_s, new_key.to_s])
    end

    # Renames old_key to newkey if newkey does not yet exist.
    #
    # **Return value**: "OK"
    def renamenx(old_key, new_key)
      integer_command(["RENAMENX", old_key.to_s, new_key.to_s])
    end

    # Removes the specified keys.
    #
    # **Return value**: Integer: The number of keys that were removed.
    def del(*keys)
      integer_command(concat(["DEL"], keys))
    end

    # Returns or stores the elements contained in the list, set or sorted set at key.
    #
    # **Options**:
    #
    # * by - pattern for sorting by external keys
    # * limit - Array of 2 strings [offset, count]
    # * get - pattern for retrieving external keys
    # * order - either 'ASC' or 'DESC'
    # * alpha - true to sort lexicographically
    # * store - key of destination list to store the result in
    #
    # **Return value**: Array(String): list of sorted elements.
    def sort(key, by = nil, limit = nil, get = nil : Array(RedisValue)?, order = "ASC", alpha = false : Boolean, store = nil)
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

    # Returns the values of all specified keys.
    #
    # **Return value**: Array(String): List of values at the specified keys.
    # For every key that does not hold a string value or does not exist, nil is returned.
    def mget(*keys)
      string_array_command(concat(["MGET"], keys))
    end

    # Sets the given keys to their respective values as defined in the hash.
    #
    # **Return value**: Always "OK"
    def mset(hash)
      q = ["MSET"] of RedisValue
      hash.each { |key, value| q << key.to_s << value.to_s }
      string_command(q)
    end

    # Atomically sets key to value and returns the old value stored at key.
    #
    # **Return value**: The old value stored at key, or nil when key did not exist.
    def getset(key, value)
      string_or_nil_command(["GETSET", key.to_s, value])
    end

    # Set key to hold the string value and set key to timeout after a given number of seconds.
    #
    # **Return value**: Always "OK"
    def setex(key, value, expire_in_seconds)
      string_command(["SETEX", key.to_s, expire_in_seconds.to_s, value.to_s])
    end

    # PSETEX works exactly like SETEX with the sole difference that the expire time is specified in milliseconds instead of seconds.
    #
    # **Return value**: Always "OK"
    def psetex(key, value, expire_in_milis)
      string_command(["PSETEX", key.to_s, expire_in_milis.to_s, value.to_s])
    end

    # Set key to hold string value if key does not exist.
    #
    # **Return value**: Integer reply, specifically:
    # * 1 if the key was set
    # * 0 if the key was not set
    def setnx(key, value)
      integer_command(["SETNX", key.to_s, value.to_s])
    end

    # Sets the given keys to their respective values as defined in the hash.
    # MSETNX will not perform any operation at all even if just a single key already exists.
    #
    # **Return value**: Integer reply, specifically:
    # * 1 if the all the keys were set.
    # * 0 if no key was set (at least one key already existed).
    def msetnx(hash)
      q = ["MSETNX"] of RedisValue
      hash.each { |key, value| q << key.to_s << value }
      integer_command(q)
    end

    # Increments the number stored at key by one.
    #
    # **Return value**: Integer: the value of key after the increment
    def incr(key)
      integer_command(["INCR", key.to_s])
    end

    # Decrements the number stored at key by one.
    #
    # **Return value**: Integer: the value of key after the decrement
    def decr(key)
      integer_command(["DECR", key.to_s])
    end

    # Increments the number stored at key by increment.
    #
    # **Return value**: Integer: the value of key after the increment
    def incrby(key, increment)
      integer_command(["INCRBY", key.to_s, increment.to_s])
    end

    # Increment the string representing a floating point number stored at key by the specified increment.
    #
    # **Return value**: Integer: the value of key after the increment
    def incrbyfloat(key, increment)
      string_command(["INCRBYFLOAT", key.to_s, increment.to_s])
    end

    # Decrements the number stored at key by decrement.
    #
    # **Return value**: Integer: the value of key after the decrement
    def decrby(key, decrement)
      integer_command(["DECRBY", key.to_s, decrement.to_s])
    end

    # If key already exists and is a string, this command appends the value at the end of the string.
    # If key does not exist it is created and set as an empty string, so APPEND will be similar to SET in this special case.
    #
    # **Return value**: Integer: the length of the string after the append operation.
    def append(key, value)
      integer_command(["APPEND", key.to_s, value.to_s])
    end

    # Returns the length of the string value stored at key.
    #
    # **Return value**: Integer: the length of the string at key, or 0 when key does not exist.
    def strlen(key)
      integer_command(["STRLEN", key.to_s])
    end

    # Returns the substring of the string value stored at key, determined by the offsets start and end (both are inclusive).
    #
    def getrange(key, start_index, end_index)
      string_command(["GETRANGE", key.to_s, start_index.to_s, end_index.to_s])
    end

    # Overwrites part of the string stored at key, starting at the specified offset, for the entire length of value.
    #
    # **Return value**: Integer: the length of the string after it was modified by the command.
    def setrange(key, start_index, value)
      integer_command(["SETRANGE", key.to_s, start_index.to_s, value.to_s])
    end

    # Count the number of set bits (population counting) in a string.
    # By default all the bytes contained in the string are examined.
    #
    # **Options**:
    #
    # * from / to - It is possible to specify the counting operation only in an interval passing the additional arguments from and to.
    #
    # **Return value** Integer: The number of bits set to 1.
    def bitcount(key, from = nil, to = nil)
      q = ["BITCOUNT", key.to_s]
      if from
        if to
          q << from.to_s
          q << to.to_s
        else
          raise Redis::Error.new("from specified, but not to")
        end
      end
      integer_command(q)
    end

    # Perform a bitwise operation between multiple keys (containing string values) and store the result in the destination key.
    #
    # **Return value**: Integer: The size of the string stored in the destination key, that is equal to the size of the longest input string.
    def bitop(operation, key, *keys)
      integer_command(concat(["BITOP", operation.to_s, key.to_s], keys))
    end

    # Returns the bit value at offset in the string value stored at key.
    #
    # **Return value**: Integer: the bit value stored at offset.
    def getbit(key, index)
      integer_command(["GETBIT", key.to_s, index.to_s])
    end

    # Sets or clears the bit at offset in the string value stored at key.
    #
    # **Return value**: Integer: the original bit value stored at offset.
    def setbit(key, index, value)
      integer_command(["SETBIT", key.to_s, index.to_s, value.to_s])
    end

    # Return the position of the first bit set to 1 or 0 in a string.
    #
    # **Options**:
    #
    # * start / to - By default, all the bytes contained in the string are examined. It is possible to look for bits only in a specified interval passing the additional arguments start and to (it is possible to just pass start, the operation will assume that the to is the last byte of the string.
    #
    # **Return value**: Integer: The command returns the position of the first bit set to 1 or 0 according to the request.
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

    # Serialize the value stored at key in a Redis-specific format and return it to the user.
    #
    # **Return value**: String:the serialized value.
    def dump(key)
      string_command(["DUMP", key.to_s])
    end

    # Create a key associated with a value that is obtained by deserializing the provided serialized value (obtained via DUMP).
    #
    # **Return value**: The command returns "OK" on success.
    def restore(key, ttl_in_milis : Int, serialized_value : String, replace = false)
      q = ["RESTORE", key.to_s, ttl_in_milis.to_s, serialized_value]
      if replace
        q << "REPLACE"
      end
      string_command(q)
    end

    # The SCAN command and the closely related commands SSCAN, HSCAN and ZSCAN are used in order to incrementally iterate over a collection of elements.
    #
    # **Options**:
    #
    # * match - It is possible to only iterate elements matching a given glob-style pattern, similarly to the behavior of the KEYS command that takes a pattern as only argument.
    # * count - While SCAN does not provide guarantees about the number of elements returned at every iteration, it is possible to empirically adjust the behavior of SCAN using the COUNT option.
    #
    # **Return value**: Array of String: A list of keys.
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

    # Return a random key from the currently selected database.
    def randomkey
      string_command(["RANDOMKEY"])
    end

    # Returns if key exists.
    #
    # **Return value**:
    # * 1 if the key exists.
    # * 0 if the key does not exist.
    def exists(key)
      integer_command(["EXISTS", key.to_s])
    end

    # Returns all keys matching pattern.
    #
    # **Return value**: Array of keys matching pattern.
    def keys(pattern)
      string_array_command(["KEYS", pattern.to_s])
    end

    # Insert all the specified values at the tail of the list stored at key.
    #
    # **Return value**: Integer: the length of the list after the push operation.
    def rpush(key, *values)
      integer_command(concat(["RPUSH", key.to_s], values))
    end

    # Insert all the specified values at the head of the list stored at key.
    #
    # **Return value**: Integer: the length of the list after the push operation.
    def lpush(key, *values)
      integer_command(concat(["LPUSH", key.to_s], values))
    end

    # Inserts value at the head of the list stored at key, only if key already exists and holds a list.
    #
    # **Return value**: Integer: the length of the list after the push operation.
    def lpushx(key, value)
      integer_command(["LPUSHX", key.to_s, value.to_s])
    end

    # Inserts value at the tail of the list stored at key, only if key already exists and holds a list.
    #
    # **Return value**: Integer: the length of the list after the push operation.
    def rpushx(key, value)
      integer_command(["RPUSHX", key.to_s, value.to_s])
    end

    # Removes the first count occurrences of elements equal to value from the list stored at key.
    #
    # **Return value**: Integer: the number of removed elements.
    def lrem(key, count, value)
      integer_command(["LREM", key.to_s, count.to_s, value.to_s])
    end

    # Returns the length of the list stored at key.
    #
    # **Return value**: Integer: the length of the list at key.
    def llen(key)
      integer_command(["LLEN", key.to_s])
    end

    # Returns the element at index index in the list stored at key.
    #
    # **Return value**: String: the requested element, or nil when index is out of range.
    def lindex(key, index)
      string_or_nil_command(["LINDEX", key.to_s, index.to_s])
    end

    # Sets the list element at index to value.
    #
    # **Return value**: "OK"
    def lset(key, index, value)
      string_command(["LSET", key.to_s, index.to_s, value.to_s])
    end

    # Removes and returns the first element of the list stored at key.
    #
    # **Return value**: the value of the first element, or nil when key does not exist.
    def lpop(key)
      string_or_nil_command(["LPOP", key.to_s])
    end

    # Removes and returns the last element of the list stored at key.
    #
    # **Return value**: "OK"
    def rpop(key)
      string_or_nil_command(["RPOP", key.to_s])
    end

    # Inserts value in the list stored at key either before or after the reference value pivot.
    #
    # **Options**:
    #
    # * where - either "BEFORE" or "AFTER"
    #
    # **Return value**: Integer: the length of the list after the insert operation, or -1 when the value pivot was not found.
    def linsert(key, where, pivot, value)
      integer_command(["LINSERT", key.to_s, where.to_s, pivot.to_s, value.to_s])
    end

    # Returns the specified elements of the list stored at key.
    #
    # **Return value**: list of elements in the specified range.
    def lrange(key, from, to)
      string_array_command(["LRANGE", key.to_s, from.to_s, to.to_s])
    end

    # Trim an existing list so that it will contain only the specified range of elements specified.
    #
    # **Return value**: "OK"
    def ltrim(key, start, stop)
      string_command(["LTRIM", key.to_s, start.to_s, stop.to_s])
    end

    # Add the specified members to the set stored at key.
    #
    # **Return value**: Integer: the number of elements that were added to the set, not including all the elements already present into the set.
    def sadd(key, *values)
      integer_command(concat(["SADD", key.to_s], values))
    end

    # Returns all the members of the set value stored at key.
    #
    # **Return value**: all elements of the set.
    def smembers(key)
      string_array_command(["SMEMBERS", key.to_s])
    end

    # Returns if member is a member of the set stored at key.
    #
    # **Return value**: Integer, specifically:
    # * 1 if the element is a member of the set.
    # * 0 if the element is not a member of the set, or if key does not exist.
    def sismember(key, value)
      integer_command(["SISMEMBER", key.to_s, value.to_s])
    end

    # Remove the specified members from the set stored at key.
    #
    # **Return value**: Integer: The number of members that were removed from the set, not including non existing members.
    def srem(key, *values)
      integer_command(concat(["SREM", key.to_s], values))
    end

    # Returns the set cardinality (number of elements) of the set stored at key.
    def scard(key)
      integer_command(["SCARD", key.to_s])
    end

    # Returns the members of the set resulting from the difference between the first set and all the successive sets.
    #
    # **Return value**: List with members of the resulting set.
    def sdiff(*keys)
      string_array_command(concat(["SDIFF"], keys))
    end

    # This command is equal to SDIFF, but instead of returning the resulting set, it is stored in destination.
    #
    # **Return value**: Integer: The number of elements in the resulting set.
    def sdiffstore(destination, *keys)
      integer_command(concat(["SDIFFSTORE", destination.to_s], keys))
    end

    # Returns the members of the set resulting from the intersection of all the given sets.
    #
    # **Return value**: Array with members of the resulting set.
    def sinter(*keys)
      string_array_command(concat(["SINTER"], keys))
    end

    # This command is equal to SINTER, but instead of returning the resulting set, it is stored in destination.
    #
    # **Return value**: Integer: The number of elements in the resulting set.
    def sinterstore(destination_key, *keys)
      integer_command(concat(["SINTERSTORE", destination_key.to_s], keys))
    end

    # Move member from the set at source to the set at destination.
    #
    # **Return value**: Integer, specifically:
    # * 1 if the element is moved.
    # * 0 if the element is not a member of source and no operation was performed.
    def smove(source, destination, member)
      integer_command(["SMOVE", source.to_s, destination.to_s, member.to_s])
    end

    # Removes and returns one or more random elements from the set value store at key.
    #
    # The count argument will be available in a later Redis version and is not available in 2.6, 2.8, 3.0
    #
    # **Return value**: The removed element, or nil when key does not exist.
    def spop(key, count = nil)
      q = ["SPOP", key.to_s]
      # Redis 3.0 should have the "count" argument, but doesn't yet.
      if count
        q << count.to_s
      end
      string_array_or_string_command(q)
    end

    # When called with just the key argument, return a random element from the set value stored at key.
    #
    # **Options**:
    #
    # * count - Starting from Redis version 2.6, when called with the additional count argument, return an array of count distinct elements if count is positive. If called with a negative count the behavior changes and the command is allowed to return the same element multiple times.
    #
    # **Return value**:
    # * String reply: without the additional count argument the command returns a Bulk Reply with the randomly selected element, or nil when key does not exist.
    # * Array reply: when the additional count argument is passed the command returns an array of elements, or an empty array when key does not exist.
    def srandmember(key, count = nil)
      q = ["SRANDMEMBER", key.to_s]
      if count
        q << count.to_s
      end
      string_array_or_string_or_nil_command(q)
    end


    # The SCAN command and the closely related commands SSCAN, HSCAN and ZSCAN are used in order to incrementally iterate over a collection of elements.
    #
    # **Options**:
    #
    # * match - It is possible to only iterate elements matching a given glob-style pattern, similarly to the behavior of the KEYS command that takes a pattern as only argument.
    # * count - While SCAN does not provide guarantees about the number of elements returned at every iteration, it is possible to empirically adjust the behavior of SCAN using the COUNT option.
    #
    # **Return value**: Array of String: A list of Set members.
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

    # Returns the members of the set resulting from the union of all the given sets.
    #
    # **Return value**: Array(String) with members of the resulting set.
    def sunion(*keys)
      string_array_command(concat(["SUNION"], keys))
    end

    # This command is equal to SUNION, but instead of returning the resulting set, it is stored in destination.
    #
    # **Return value**: Integer: The number of elements in the resulting set.
    def sunionstore(destination, *keys)
      integer_command(concat(["SUNIONSTORE", destination.to_s], keys))
    end

    # BLPOP is a blocking list pop primitive.
    # It is the blocking version of LPOP because it blocks the connection when there
    # are no elements to pop from any of the given lists.
    # An element is popped from the head of the first list that is non-empty,
    # with the given keys being checked in the order that they are given.
    #
    # The timeout_in_seconds argument is interpreted as an integer value specifying the maximum number of seconds to block
    #
    # **Return value**: Array reply, specifically:
    # * An array of nils when no element could be popped and the timeout expired.
    # * An array of two-element arrays with the first element being the name of the key where an element was popped and the second element being the value of the popped element.
    def blpop(keys, timeout_in_seconds)
      q = concat(["BLPOP"], keys)
      q << timeout_in_seconds.to_s
      array_or_nil_command(q)
    end

    # BRPOP is a blocking list pop primitive.
    # It is the blocking version of RPOP because it blocks the connection when there
    # are no elements to pop from any of the given lists.
    # An element is popped from the tail of the first list that is non-empty,
    # with the given keys being checked in the order that they are given.
    #
    # The timeout_in_seconds argument is interpreted as an integer value specifying the maximum
    # number of seconds to block.
    #
    # **Return value**: Array reply, specifically:
    # * An array of nils when no element could be popped and the timeout expired.
    # * An array of two-element arrays with the first element being the name of the key where an element was popped and the second element being the value of the popped element.
    def brpop(keys, timeout_in_seconds)
      q = concat(["BRPOP"], keys)
      q << timeout_in_seconds.to_s
      array_or_nil_command(q)
    end

    # Atomically returns and removes the last element (tail) of the list stored at source,
    # and pushes the element at the first element (head) of the list stored at destination.
    #
    # **Return value**: String: The element being popped and pushed.
    def rpoplpush(source, destination)
      string_or_nil_command(["RPOPLPUSH", source.to_s, destination.to_s])
    end

    # BRPOPLPUSH is the blocking variant of RPOPLPUSH.
    # When source contains elements, this command behaves exactly like RPOPLPUSH.
    #
    # **Options**:
    #
    # * timeout_in_seconds - interpreted as an integer value specifying the maximum number of seconds to block
    #
    # See RPOPLPUSH for more information.
    #
    # **Return value**: String: The element being popped from source and pushed to destination.
    # If timeout is reached, nil is returned.
    def brpoplpush(source, destination, timeout_in_seconds = nil)
      q = ["BRPOPLPUSH", source.to_s, destination.to_s]
      if timeout_in_seconds
        q <<  timeout_in_seconds.to_s
      end
      string_or_nil_command(q)
    end

    # Sets field in the hash stored at key to value.
    #
    # **Return value**: Integer, specifically:
    # * 1 if field is a new field in the hash and value was set.
    # * 0 if field already exists in the hash and the value was updated.
    def hset(key, field, value)
      integer_command(["HSET", key.to_s, field.to_s, value.to_s])
    end

    # Returns the value associated with field in the hash stored at key.
    #
    # **Return value**: The value associated with field, or nil
    def hget(key, field)
      string_or_nil_command(["HGET", key.to_s, field.to_s])
    end

    # Returns all fields and values of the hash stored at key.
    #
    # **Return value**: Array(String) of fields and their values stored in the hash,
    # or an empty array when key does not exist.
    def hgetall(key)
      string_array_command(["HGETALL", key.to_s])
    end

    # Removes the specified fields from the hash stored at key.
    #
    # **Return value**: Integer: the number of fields that were removed from the hash,
    # not including specified but non existing fields.
    def hdel(key, field)
      integer_command(["HDEL", key.to_s, field.to_s])
    end

    # Returns if field is an existing field in the hash stored at key.
    #
    # **Return value**: Integer, specifically:
    # * 1 if the hash contains field.
    # * 0 if the hash does not contain field, or key does not exist.
    def hexists(key, field)
      integer_command(["HEXISTS", key.to_s, field.to_s])
    end

    # Increments the number stored at field in the hash stored at key by increment.
    #
    # **Return value**: Integer: The value at field after the increment operation.
    def hincrby(key, field, increment)
      integer_command(["HINCRBY", key.to_s, field.to_s, increment.to_s])
    end

    # Increment the specified field of an hash stored at key,
    # and representing a floating point number, by the specified increment.
    #
    # **Return value**: String: The value at field after the increment operation.
    def hincrbyfloat(key, field, increment)
      string_command(["HINCRBYFLOAT", key.to_s, field.to_s, increment.to_s])
    end

    # Returns all field names in the hash stored at key.
    #
    # **Return value**: Array(String): List of fields in the hash, or an empty list when key does not exist.
    def hkeys(key)
      string_array_command(["HKEYS", key.to_s])
    end

    # Returns the number of fields contained in the hash stored at key.
    #
    # **Return value**: Integer: Number of fields in the hash, or 0 when key does not exist.
    def hlen(key)
      integer_command(["HLEN", key.to_s])
    end

    # Returns the values associated with the specified fields in the hash stored at key.
    #
    # **Return value**: Array(String): list of values associated with the given fields, in the same order as they are requested.
    def hmget(key, *fields)
      string_array_command(concat(["HMGET", key.to_s], fields))
    end

    # Sets the specified fields to their respective values in the hash stored at key.
    #
    # **Return value**: "OK"
    def hmset(key, hash)
      q = ["HMSET", key.to_s] of RedisValue
      hash.each { |field, value| q << field.to_s << value }
      string_command(q)
    end

    # The SCAN command and the closely related commands SSCAN, HSCAN and ZSCAN are used in order to incrementally iterate over a collection of elements.
    #
    # **Options**:
    #
    # * match - It is possible to only iterate elements matching a given glob-style pattern, similarly to the behavior of the KEYS command that takes a pattern as only argument.
    # * count - While SCAN does not provide guarantees about the number of elements returned at every iteration, it is possible to empirically adjust the behavior of SCAN using the COUNT option.
    #
    # **Return value**: Array(String): Two elements, a field and a value, for every returned element of the Hash.
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

    # Sets field in the hash stored at key to value, only if field does not yet exist.
    #
    # **Return value**: Integer, specifically:
    # * 1 if field is a new field in the hash and value was set.
    # * 0 if field already exists in the hash and no operation was performed.
    def hsetnx(key, field, value)
      integer_command(["HSETNX", key.to_s, field.to_s, value.to_s])
    end

    # Returns all values in the hash stored at key.
    #
    # **Return value**: Array(String): List of values in the hash, or an empty list when key does not exist.
    def hvals(key)
      string_array_command(["HVALS", key.to_s])
    end

    # Adds all the specified members with the specified scores to the sorted set stored at key.
    #
    # **Return value**: Integer: The number of elements added to the sorted sets, not including elements already existing for which the score was updated.
    def zadd(key, *scores_and_members)
      if scores_and_members.length % 2 > 0
        raise Error.new("zadd expects an array of scores mapped to members")
      end

      integer_command(concat(["ZADD", key.to_s], scores_and_members))
    end

    # Returns the specified range of elements in the sorted set stored at key.
    #
    # **Options**:
    #
    # * with_scores - true to return the scores of the elements together with the elements.
    #
    # **Return value**: Array(String): List of elements in the specified range (optionally with their scores, in case the with_scores option is true).
    def zrange(key, start, stop, with_scores = false)
      q = ["ZRANGE", key.to_s, start.to_s, stop.to_s]
      if with_scores
        q << "WITHSCORES"
      end
      string_array_command(q)
    end

    # Returns the sorted set cardinality (number of elements) of the sorted set stored at key.
    #
    # **Return value**: Integer: the cardinality (number of elements) of the sorted set, or 0 if key does not exist.
    def zcard(key)
      integer_command(["ZCARD", key.to_s])
    end

    # Returns the score of member in the sorted set at key.
    #
    # **Return value**: String: The score of member (a double precision floating point number).
    def zscore(key, member)
      string_or_nil_command(["ZSCORE", key.to_s, member.to_s])
    end

    # Returns the number of elements in the sorted set at key with a score between min and max.
    #
    # **Return value**: The number of elements in the specified score range.
    def zcount(key, min, max)
      integer_command(["ZCOUNT", key.to_s, min.to_s, max.to_s])
    end

    # When all the elements in a sorted set are inserted with the same score, in order to force lexicographical ordering, this command returns the number of elements in the sorted set at key with a value between min and max.
    #
    # **Return value**: Integer: The number of elements in the specified score range.
    def zlexcount(key, min, max)
      integer_command(["ZLEXCOUNT", key.to_s, min.to_s, max.to_s])
    end

    # Increments the score of member in the sorted set stored at key by increment.
    #
    # **Return value**: String: The new score of member (a double precision floating point number represented as String).
    def zincrby(key, increment, member)
      string_command(["ZINCRBY", key.to_s, increment.to_s, member.to_s])
    end

    # Removes the specified members from the sorted set stored at key.
    #
    # **Return value**: Integer: The number of members removed from the sorted set, not including non existing members.
    def zrem(key, member)
      integer_command(["ZREM", key.to_s, member.to_s])
    end

    # Returns the rank of member in the sorted set stored at key, with the scores ordered from low to high.
    #
    # **Return value**:
    # * If member exists in the sorted set, Integer: the rank of member.
    # * If member does not exist in the sorted set or key does not exist: nil.
    def zrank(key, member)
      integer_or_nil_command(["ZRANK", key.to_s, member.to_s])
    end

    # Returns the rank of member in the sorted set stored at key,
    # with the scores ordered from high to low.
    #
    # **Return value**:
    # * If member exists in the sorted set, Integer: the rank of member.
    # * If member does not exist in the sorted set or key does not exist: nil.
    def zrevrank(key, member)
      integer_or_nil_command(["ZREVRANK", key.to_s, member.to_s])
    end

    # Computes the intersection of numkeys sorted sets given by the specified keys,
    # and stores the result in destination.
    #
    # **Options**:
    #
    # * weights - nil or Array(String): Using the WEIGHTS option, it is possible to specify a multiplication factor for each input sorted set.
    # * aggregate - With the AGGREGATE option, it is possible to specify how the results of the union are aggregated.
    #
    # **Return value**: Integer: The number of elements in the resulting sorted set at destination.
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

    # Computes the union of numkeys sorted sets given by the specified keys, and stores the result in destination.
    #
    # **Options**:
    #
    # * weights - nil or Array(String): Using the WEIGHTS option, it is possible to specify a multiplication factor for each input sorted set.
    # * aggregate - With the AGGREGATE option, it is possible to specify how the results of the union are aggregated.
    #
    # **Return value**: Integer: The number of elements in the resulting sorted set at destination.
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

    # When all the elements in a sorted set are inserted with the same score,
    # in order to force lexicographical ordering, this command returns all the
    # elements in the sorted set at key with a value between min and max.
    #
    # **Options**:
    #
    # * limit - an array of [offset, count]. Skip offset members, return a maximum of count members.
    #
    # **Return value**:
    def zrangebylex(key, min, max, limit = nil)
      q = ["ZRANGEBYLEX", key.to_s, min.to_s, max.to_s]
      if limit
        q << "LIMIT" << limit[0].to_s << limit[1].to_s
      end
      string_array_command(q)
    end

    # Returns all the elements in the sorted set at key with a score between
    # max and min (including elements with score equal to max or min).
    #
    # **Options**:
    #
    # * limit - an array of [offset, count]. Skip offset members, return a maximum of count members.
    # * with_scores - true to return the scores of the elements together with the elements.
    #
    # **Return value**: List of elements in the specified score range (optionally with their scores).
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

    #
    #
    # **Return value**:
    def zrevrange(key, start, stop, with_scores = false)
      q = ["ZREVRANGE", key.to_s, start.to_s, stop.to_s]
      if with_scores
        q << "WITHSCORES"
      end

      string_array_command(q)
    end

    #
    #
    # **Return value**:
    def zrevrangebylex(key, min, max, limit = nil)
      q = ["ZREVRANGEBYLEX", key.to_s, min.to_s, max.to_s]
      if limit
        q << "LIMIT" << limit[0].to_s << limit[1].to_s
      end
      string_array_command(q)
    end

    #
    #
    # **Return value**:
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

    #
    #
    # **Return value**:
    def zremrangebylex(key, min, max)
      integer_command(["ZREMRANGEBYLEX", key.to_s, min.to_s, max.to_s])
    end

    #
    #
    # **Return value**:
    def zremrangebyrank(key, start, stop)
      integer_command(["ZREMRANGEBYRANK", key.to_s, start.to_s, stop.to_s])
    end

    #
    #
    # **Return value**:
    def zremrangebyscore(key, start, stop)
      integer_command(["ZREMRANGEBYSCORE", key.to_s, start.to_s, stop.to_s])
    end

    #
    #
    # **Return value**:
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

    #
    #
    # **Return value**:
    def pfadd(key, *values)
      integer_command(concat(["PFADD", key.to_s], values))
    end

    #
    #
    # **Return value**:
    def pfmerge(*keys)
      string_command(concat(["PFMERGE"], keys))
    end

    #
    #
    # **Return value**:
    def pfcount(key)
      integer_command(["PFCOUNT", key.to_s])
    end

    #
    #
    # **Return value**:
    def eval(script : String, keys = [] of RedisValue, args = [] of RedisValue)
      string_array_command(concat(["EVAL", script, keys.length.to_s], keys, args))
    end

    #
    #
    # **Return value**:
    def evalsha(sha1, keys = [] of RedisValue, args = [] of RedisValue)
      string_array_command(concat(["EVALSHA", sha1.to_s, keys.length.to_s], keys, args))
    end

    #
    #
    # **Return value**:
    def script_load(script : String)
      string_command(["SCRIPT", "LOAD", script])
    end

    #
    #
    # **Return value**:
    def script_kill
      string_command(["SCRIPT", "KILL"])
    end

    #
    #
    # **Return value**:
    def script_exists(sha1_array : Array(Reference))
      integer_array_command(concat(["SCRIPT", "EXISTS"], sha1_array))
    end

    #
    #
    # **Return value**:
    def script_flush
      string_command(["SCRIPT", "FLUSH"])
    end

    #
    #
    # **Return value**:
    def expire(key, seconds)
      integer_command(["EXPIRE", key.to_s, seconds.to_s])
    end

    #
    #
    # **Return value**:
    def pexpire(key, milis)
      integer_command(["PEXPIRE", key.to_s, milis.to_s])
    end

    #
    #
    # **Return value**:
    def expireat(key, unix_date)
      integer_command(["EXPIREAT", key.to_s, unix_date.to_s])
    end

    #
    #
    # **Return value**:
    def pexpireat(key, unix_date_in_milis)
      integer_command(["PEXPIREAT", key.to_s, unix_date_in_milis.to_s])
    end

    #
    #
    # **Return value**:
    def persist(key)
      integer_command(["PERSIST", key.to_s])
    end

    #
    #
    # **Return value**:
    def ttl(key)
      integer_command(["TTL", key.to_s])
    end

    #
    #
    # **Return value**:
    def pttl(key)
      integer_command(["PTTL", key.to_s])
    end

    #
    #
    # **Return value**:
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

    #
    #
    # **Return value**:
    def unsubscribe(*channels)
      void_command(concat(["UNSUBSCRIBE"], channels))
    end

    #
    #
    # **Return value**:
    def punsubscribe(*channel_patterns)
      void_command(concat(["PUNSUBSCRIBE"], channel_patterns))
    end

    #
    #
    # **Return value**:
    def publish(channel, message)
      integer_command(["PUBLISH", channel.to_s, message.to_s])
    end

    #
    #
    # **Return value**:
    def watch(*keys)
      string_command(concat(["WATCH"], keys))
    end

    #
    #
    # **Return value**:
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
