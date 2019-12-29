class Redis
  # Definition of all Redis commands except pipelining and transactions.
  #
  module Commands
    # Returns the given message.
    #
    # Example:
    #
    # ```
    # redis.echo("Hello Redis") # => "Hello Redis"
    # ```
    def echo(message)
      string_command(["ECHO", message.to_s])
    end

    # Returns PONG. This command is often used to test if a connection is still alive, or to measure latency.
    #
    # Example:
    #
    # ```
    # redis.ping # => "PONG"
    # ```
    def ping
      string_command(["PING"])
    end

    # Set key to hold the string value. If key already holds a value, it is overwritten, regardless of its type. Any previous time to live associated with the key is discarded on successful SET operation.
    #
    # **Options**:
    #
    # * Starting with Redis 2.6.12 SET supports a set of options that modify its behavior:
    # * ex -- Set the specified expire time, in seconds.
    # * px -- Set the specified expire time, in milliseconds.
    # * nx -- Only set the key if it does not already exist.
    # * xx -- Only set the key if it already exist.
    #
    # **Return value**:
    # * OK if SET was executed correctly.
    # * Null reply: nil is returned if the SET operation was not performed because the user specified the NX or XX option but the condition was not met.
    #
    # Example:
    #
    # ```
    # redis.set("foo", "test")
    # redis.set("bar", "test", ex: 7)
    # ```
    def set(key, value, ex = nil, px = nil, nx = nil, xx = nil)
      q = ["SET", namespaced(key), value.to_s]
      q << "EX" << ex.to_s if ex
      q << "PX" << px.to_s if px
      q << "NX" if nx
      q << "XX" if xx
      string_or_nil_command(q)
    end

    # Get the value of key.
    #
    # **Return value**: a String or nil
    #
    # Example:
    #
    # ```
    # redis.set("foo", "test")
    # redis.get("foo") # => "test"
    # ```
    def get(key)
      string_or_nil_command(["GET", namespaced(key)])
    end

    # Ask the server to close the connection. The connection is closed as soon as all pending replies have been written to the client.
    #
    # **Return value**: "OK"
    def quit
      string_command(["QUIT"])
    end

    # Remove all keys from the current database.
    #
    # **Return value**: "OK"
    def flushdb
      string_command(["FLUSHDB"])
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
      if !database_number
        raise Redis::Error.new("ERR database number could not be Nil")
      end
      if database_number == @database
        # Performance optimization
        return "OK"
      end
      res = string_command(["SELECT", database_number.to_s])
      @database = database_number
      res
    end

    # Renames old_key to newkey.
    #
    # **Return value**: "OK"
    #
    # Example:
    #
    # ```
    # redis.rename("old_name", "new_name")
    # ```
    def rename(old_key, new_key)
      string_command(["RENAME", namespaced(old_key), namespaced(new_key)])
    end

    # Renames old_key to newkey if newkey does not yet exist.
    #
    # **Return value**: "OK"
    #
    # Example:
    #
    # ```
    # redis.renamenx("old_name", "new_name")
    # ```
    def renamenx(old_key, new_key)
      integer_command(["RENAMENX", namespaced(old_key), namespaced(new_key)])
    end

    # Removes the specified keys.
    #
    # **Return value**: Integer, the number of keys that were removed.
    #
    # Example:
    #
    # ```
    # redis.del("some", "keys", "to", "delete")
    # ```
    def del(*keys)
      del keys.to_a
    end

    # Removes the specified keys.
    #
    # **Return value**: Integer, the number of keys that were removed.
    #
    # Example:
    #
    # ```
    # redis.del(["some", "keys", "to", "delete"])
    # ```
    def del(keys : Array)
      integer_command(concat(["DEL"], namespaced(keys)))
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
    # **Return value**: Array(String), the list of sorted elements.
    #
    # Example:
    #
    # ```
    # redis.sort("mylist")                # => [...]
    # redis.sort("mylist", order: "DESC") # => [...]
    # ```
    def sort(key, by = nil, limit = nil, get : Array(RedisValue)? = nil, order = "ASC", alpha = false, store = nil)
      q = ["SORT", namespaced(key)]

      if by
        q << "BY" << by.to_s
      end

      if limit
        if limit.size != 2
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
        q << "STORE" << namespaced(store)
      end

      string_array_or_integer_command(q)
    end

    # Returns the values of all specified keys.
    #
    # **Return value**: Array(String), the list of values at the specified keys.
    # For every key that does not hold a string value or does not exist, nil is returned.
    #
    # Example:
    #
    # ```
    # redis.set("foo1", "test1")
    # redis.set("foo2", "test2")
    # redis.mget("foo1", "foo2") # => ["test1", "test2"]
    # ```
    def mget(*keys)
      string_array_command(concat(["MGET"], namespaced(keys)))
    end

    def mget(keys : Array(String)) : Array(RedisValue)
      string_array_command(concat(["MGET"], namespaced(keys)))
    end

    # Sets the given keys to their respective values as defined in the hash.
    #
    # **Return value**: "OK"
    #
    # Example:
    #
    # ```
    # redis.mset({"foo1": "bar1", "foo2": "bar2"})
    # ```
    def mset(hash : Hash)
      q = ["MSET"] of RedisValue
      hash.each { |key, value| q << namespaced(key) << value.to_s }
      string_command(q)
    end

    # Atomically sets key to value and returns the old value stored at key.
    #
    # **Return value**: String, the old value stored at key, or nil when key did not exist.
    #
    # Example:
    #
    # ```
    # redis.getset("foo", "new") # => (the old value)
    # ```
    def getset(key, value)
      string_or_nil_command(["GETSET", namespaced(key), value])
    end

    # Set key to hold the string value and set key to timeout after a given number of seconds.
    #
    # **Return value**: "OK"
    #
    # Example:
    #
    # ```
    # redis.setex("foo", 3, "bar")
    # ```
    def setex(key, expire_in_seconds, value)
      string_command(["SETEX", namespaced(key), expire_in_seconds.to_s, value.to_s])
    end

    # PSETEX works exactly like SETEX with the sole difference that the expire time is specified in milliseconds instead of seconds.
    #
    # **Return value**: "OK"
    def psetex(key, expire_in_milis, value)
      string_command(["PSETEX", namespaced(key), expire_in_milis.to_s, value.to_s])
    end

    # Set key to hold string value if key does not exist.
    #
    # **Return value**: Integer, specifically:
    # * 1 if the key was set
    # * 0 if the key was not set
    def setnx(key, value)
      integer_command(["SETNX", namespaced(key), value.to_s])
    end

    # Sets the given keys to their respective values as defined in the hash.
    # MSETNX will not perform any operation at all even if just a single key already exists.
    #
    # **Return value**: Integer, specifically:
    # * 1 if the all the keys were set.
    # * 0 if no key was set (at least one key already existed).
    #
    # Example:
    #
    # ```
    # redis.msetnx({"key1": "hello", "key2": "there"})
    # ```
    def msetnx(hash)
      q = ["MSETNX"] of RedisValue
      hash.each { |key, value| q << namespaced(key) << value }
      integer_command(q)
    end

    # Increments the number stored at key by one.
    #
    # **Return value**: Integer: the value of key after the increment
    #
    # Example:
    #
    # ```
    # redis.set("foo", "3")
    # redis.incr("foo") # => 4
    # ```
    def incr(key)
      integer_command(["INCR", namespaced(key)])
    end

    # Decrements the number stored at key by one.
    #
    # **Return value**: Integer, the value of key after the decrement
    def decr(key)
      integer_command(["DECR", namespaced(key)])
    end

    # Increments the number stored at key by increment.
    #
    # **Return value**: Integer, the value of key after the increment
    #
    # Example:
    #
    # ```
    # redis.incrby("foo", 4)
    # ```
    def incrby(key, increment)
      integer_command(["INCRBY", namespaced(key), increment.to_s])
    end

    # Increment the string representing a floating point number stored at key by the specified increment.
    #
    # **Return value**: Integer, the value of key after the increment
    #
    # Example:
    #
    # ```
    # redis.incrbyfloat("foo", 2.5)
    # ```
    def incrbyfloat(key, increment)
      string_command(["INCRBYFLOAT", namespaced(key), increment.to_s])
    end

    # Decrements the number stored at key by decrement.
    #
    # **Return value**: Integer, the value of key after the decrement
    def decrby(key, decrement)
      integer_command(["DECRBY", namespaced(key), decrement.to_s])
    end

    # If key already exists and is a string, this command appends the value at the end of the string.
    # If key does not exist it is created and set as an empty string, so APPEND will be similar to SET in this special case.
    #
    # **Return value**: Integer, the length of the string after the append operation.
    #
    # Example:
    #
    # ```
    # redis.append("foo", " world")
    # ```
    def append(key, value)
      integer_command(["APPEND", namespaced(key), value.to_s])
    end

    # Returns the length of the string value stored at key.
    #
    # **Return value**: Integer, the length of the string at key, or 0 when key does not exist.
    def strlen(key)
      integer_command(["STRLEN", namespaced(key)])
    end

    # Returns the substring of the string value stored at key, determined by the offsets start and end (both are inclusive).
    #
    #
    # Example:
    #
    # ```
    # redis.set("foo", "This is a string")
    # redis.getrange("foo", 0, 3)   # => "This"
    # redis.getrange("foo", -3, -1) # => "ing"
    # ```
    def getrange(key, start_index, end_index)
      string_command(["GETRANGE", namespaced(key), start_index.to_s, end_index.to_s])
    end

    # Overwrites part of the string stored at key, starting at the specified offset, for the entire length of value.
    #
    # **Return value**: Integer, the length of the string after it was modified by the command.
    #
    # Example:
    #
    # ```
    # redis.setrange("foo", 6, "Redis")
    # ```
    def setrange(key, start_index, value)
      integer_command(["SETRANGE", namespaced(key), start_index.to_s, value.to_s])
    end

    # Count the number of set bits (population counting) in a string.
    # By default all the bytes contained in the string are examined.
    #
    # **Options**:
    #
    # * from / to - It is possible to specify the counting operation only in an interval passing the additional arguments from and to.
    #
    # **Return value** Integer, the number of bits set to 1.
    #
    # Example:
    #
    # ```
    # redis.bitcount("foo", 0, 0)
    # ```
    def bitcount(key, from = nil, to = nil)
      q = ["BITCOUNT", namespaced(key)]
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
    # **Return value**: Integer, the size of the string stored in the destination key, that is equal to the size of the longest input string.
    #
    # Example:
    #
    # ```
    # redis.bitop("and", "dest", "key1", "key2")
    # ```
    def bitop(operation, key, keys : Array(String)) : Int64
      integer_command(concat(["BITOP", operation.to_s, namespaced(key)], namespaced(keys)))
    end

    # :ditto:
    def bitop(operation, key, *keys : String) : Int64
      bitop operation, key, keys.to_a
    end

    # Returns the bit value at offset in the string value stored at key.
    #
    # **Return value**: Integer, the bit value stored at offset.
    def getbit(key, index)
      integer_command(["GETBIT", namespaced(key), index.to_s])
    end

    # Sets or clears the bit at offset in the string value stored at key.
    #
    # **Return value**: Integer: the original bit value stored at offset.
    #
    # Example:
    #
    # ```
    # redis.setbit("mykey", 7, 1)
    # ```
    def setbit(key, index, value)
      integer_command(["SETBIT", namespaced(key), index.to_s, value.to_s])
    end

    # Return the position of the first bit set to 1 or 0 in a string.
    #
    # **Options**:
    #
    # * start / to - By default, all the bytes contained in the string are examined. It is possible to look for bits only in a specified interval passing the additional arguments start and to (it is possible to just pass start, the operation will assume that the to is the last byte of the string.
    #
    # **Return value**: Integer, the command returns the position of the first bit set to 1 or 0 according to the request.
    #
    # Example:
    #
    # ```
    # redis.set("mykey", "0")
    # redis.bitpos("mykey", 1) # => 2
    # ```
    def bitpos(key, bit, start = nil, to = nil)
      q = ["BITPOS", namespaced(key), bit.to_s] of RedisValue
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
    # **Return value**: String, the serialized value.
    def dump(key)
      string_command(["DUMP", namespaced(key)])
    end

    # Create a key associated with a value that is obtained by deserializing the provided serialized value (obtained via DUMP).
    #
    # **Return value**: The command returns "OK" on success.
    def restore(key, ttl_in_milis : Int, serialized_value : String, replace = false)
      q = ["RESTORE", namespaced(key), ttl_in_milis.to_s, serialized_value]
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
    # **Return value**: Array of String, a list of keys.
    #
    # Example:
    #
    # ```
    # redis.scan(0)
    # redis.scan(0, "foo*")
    # redis.scan(0, "foo*", 1024)
    # ```
    def scan(cursor, match = nil, count = nil)
      q = ["SCAN", cursor.to_s]
      q << "MATCH" << namespaced(match) if match
      q << "COUNT" << count.to_s if count
      result = string_array_command(q)

      result[1] = array_without_namespace(result[1])

      result
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
      integer_command(["EXISTS", namespaced(key)])
    end

    # Returns all keys matching pattern.
    #
    # **Return value**: Array(String), array of keys matching pattern.
    #
    # Example:
    #
    # ```
    # redis.keys("callmemaybe")
    # ```
    def keys(pattern)
      string_array_command(["KEYS", namespaced(pattern)]).map { |key| without_namespace("#{key}") }
    end

    # Insert all the specified values at the tail of the list stored at key.
    #
    # **Return value**: Integer, the length of the list after the push operation.
    #
    # Example:
    #
    # ```
    # redis.rpush("mylist", "1", "2", "3")
    # ```
    def rpush(key, values : Array(RedisValue))
      integer_command(concat(["RPUSH", namespaced(key)], values))
    end

    # :ditto:
    def rpush(key, *values : String)
      rpush key, values.to_a
    end

    # Insert all the specified values at the head of the list stored at key.
    #
    # **Return value**: Integer, the length of the list after the push operation.
    def lpush(key, *values)
      lpush key, values.to_a
    end

    # :ditto:
    def lpush(key, values : Array(RedisValue))
      integer_command(concat(["LPUSH", namespaced(key)], values))
    end

    # Inserts value at the head of the list stored at key, only if key already exists and holds a list.
    #
    # **Return value**: Integer, the length of the list after the push operation.
    def lpushx(key, value)
      integer_command(["LPUSHX", namespaced(key), value.to_s])
    end

    # Inserts value at the tail of the list stored at key, only if key already exists and holds a list.
    #
    # **Return value**: Integer, the length of the list after the push operation.
    def rpushx(key, value)
      integer_command(["RPUSHX", namespaced(key), value.to_s])
    end

    # Removes the first count occurrences of elements equal to value from the list stored at key.
    #
    # **Return value**: Integer, the number of removed elements.
    #
    # Example:
    #
    # ```
    # redis.lrem("mylist", 1, "my")
    # ```
    def lrem(key, count, value)
      integer_command(["LREM", namespaced(key), count.to_s, value.to_s])
    end

    # Returns the length of the list stored at key.
    #
    # **Return value**: Integer, the length of the list at key.
    def llen(key)
      integer_command(["LLEN", namespaced(key)])
    end

    # Returns the element at index index in the list stored at key.
    #
    # **Return value**: String, the requested element, or nil when index is out of range.
    def lindex(key, index)
      string_or_nil_command(["LINDEX", namespaced(key), index.to_s])
    end

    # Sets the list element at index to value.
    #
    # **Return value**: "OK"
    def lset(key, index, value)
      string_command(["LSET", namespaced(key), index.to_s, value.to_s])
    end

    # Removes and returns the first element of the list stored at key.
    #
    # **Return value**: String, the value of the first element, or nil when key does not exist.
    #
    # Example:
    #
    # ```
    # redis.lpop("mylist")
    # ```
    def lpop(key)
      string_or_nil_command(["LPOP", namespaced(key)])
    end

    # Removes and returns the last element of the list stored at key.
    #
    # **Return value**: "OK"
    def rpop(key)
      string_or_nil_command(["RPOP", namespaced(key)])
    end

    # Inserts value in the list stored at key either before or after the reference value pivot.
    #
    # **Options**:
    #
    # * where - either "BEFORE" or "AFTER"
    #
    # **Return value**: Integer, the length of the list after the insert operation, or -1 when the value pivot was not found.
    def linsert(key, where, pivot, value)
      integer_command(["LINSERT", namespaced(key), where.to_s, pivot.to_s, value.to_s])
    end

    # Returns the specified elements of the list stored at key.
    #
    # **Return value**: Array(String), the list of elements in the specified range.
    #
    # Example:
    #
    # ```
    # redis.lrange("mylist", 0, 2)
    # ```
    def lrange(key, from, to)
      string_array_command(["LRANGE", namespaced(key), from.to_s, to.to_s])
    end

    # Trim an existing list so that it will contain only the specified range of elements specified.
    #
    # **Return value**: "OK"
    def ltrim(key, start, stop)
      string_command(["LTRIM", namespaced(key), start.to_s, stop.to_s])
    end

    # Add the specified members to the set stored at key.
    #
    # **Return value**: Integer, the number of elements that were added to the set, not including all the elements already present into the set.
    def sadd(key, *values)
      sadd key, values.to_a
    end

    def sadd(key, values : Array(RedisValue))
      integer_command(concat(["SADD", namespaced(key)], values))
    end

    # Returns all the members of the set value stored at key.
    #
    # **Return value**: Array(String), all elements of the set.
    def smembers(key)
      string_array_command(["SMEMBERS", namespaced(key)])
    end

    # Returns if member is a member of the set stored at key.
    #
    # **Return value**: Integer, specifically:
    # * 1 if the element is a member of the set.
    # * 0 if the element is not a member of the set, or if key does not exist.
    def sismember(key, value)
      integer_command(["SISMEMBER", namespaced(key), value.to_s])
    end

    # Remove the specified members from the set stored at key.
    #
    # **Return value**: Integer, The number of members that were removed from the set, not including non existing members.
    #
    # Example:
    #
    # ```
    # redis.srem("myset", "Hello")
    # ```
    def srem(key, *values)
      srem key, values.to_a
    end

    def srem(key, values : Array(RedisValue))
      integer_command(concat(["SREM", namespaced(key)], values))
    end

    # Returns the set cardinality (number of elements) of the set stored at key.
    def scard(key)
      integer_command(["SCARD", namespaced(key)])
    end

    # Returns the members of the set resulting from the difference between the first set and all the successive sets.
    #
    # **Return value**: Array(String), a list with members of the resulting set.
    def sdiff(keys : Array(String)) : Array(RedisValue)
      string_array_command(concat(["SDIFF"], namespaced(keys)))
    end

    def sdiff(*keys : String) : Array(RedisValue)
      sdiff keys.to_a
    end

    # This command is equal to SDIFF, but instead of returning the resulting set, it is stored in destination.
    #
    # **Return value**: Integer, the number of elements in the resulting set.
    def sdiffstore(destination, keys : Array(String)) : Int64
      integer_command(concat(["SDIFFSTORE", namespaced(destination)], namespaced(keys)))
    end

    # :ditto:
    def sdiffstore(destination, *keys : String) : Int64
      sdiffstore destination, keys.to_a
    end

    # Returns the members of the set resulting from the intersection of all the given sets.
    #
    # **Return value**: Array(String), an array with members of the resulting set.
    def sinter(keys : Array(String)) : Array(RedisValue)
      string_array_command(concat(["SINTER"], namespaced(keys)))
    end

    # :ditto:
    def sinter(*keys : String) : Array(RedisValue)
      sinter keys.to_a
    end

    # This command is equal to SINTER, but instead of returning the resulting set, it is stored in destination.
    #
    # **Return value**: Integer, the number of elements in the resulting set.
    #
    # Example:
    #
    # ```
    # redis.sinterstore("destination", "key1", "key2")
    # ```
    def sinterstore(destination_key, keys : Array(String)) : Int64
      integer_command(concat(["SINTERSTORE", namespaced(destination_key)], namespaced(keys)))
    end

    # :ditto:
    def sinterstore(destination_key, *keys : String) : Int64
      sinterstore destination_key, keys.to_a
    end

    # Move member from the set at source to the set at destination.
    #
    # **Return value**: Integer, specifically:
    # * 1 if the element is moved.
    # * 0 if the element is not a member of source and no operation was performed.
    def smove(source, destination, member)
      integer_command(["SMOVE", namespaced(source), namespaced(destination), member.to_s])
    end

    # Removes and returns one or more random elements from the set value store at key.
    #
    # The count argument will be available in a later Redis version and is not available in 2.6, 2.8, 3.0
    #
    # **Return value**: The removed element, or nil when key does not exist.
    def spop(key, count = nil)
      q = ["SPOP", namespaced(key)]
      # Redis 3.0 should have the "count" argument, but doesn't yet.
      if count
        q << count.to_s
      end
      string_array_or_string_or_nil_command(q)
    end

    # When called with just the key argument, return a random element from the set value stored at key.
    #
    # **Options**:
    #
    # * count - Starting from Redis version 2.6, when called with the additional count argument, return an array of count distinct elements if count is positive. If called with a negative count the behavior changes and the command is allowed to return the same element multiple times.
    #
    # **Return value**:
    # * String: without the additional count argument the command returns a Bulk Reply with the randomly selected element, or nil when key does not exist.
    # * Array: when the additional count argument is passed the command returns an array of elements, or an empty array when key does not exist.
    def srandmember(key, count = nil)
      q = ["SRANDMEMBER", namespaced(key)]
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
    # **Return value**: Array(String), a list of Set members.
    #
    # Example:
    #
    # ```
    # redis.sscan("myset", 0)
    # redis.sscan("myset", 0, "foo*")
    # redis.sscan("myset", 0, "foo*", 1024)
    # ```
    def sscan(key, cursor, match = nil, count = nil)
      q = ["SSCAN", namespaced(key), cursor.to_s]
      q << "MATCH" << match.to_s if match
      q << "COUNT" << count.to_s if count
      string_array_command(q) # .map { |key| without_namespace(key) }
    end

    # Returns the members of the set resulting from the union of all the given sets.
    #
    # **Return value**: Array(String), with members of the resulting set.
    def sunion(keys : Array(String))
      string_array_command(concat(["SUNION"], namespaced(keys)))
    end

    # :ditto:
    def sunion(*keys : String)
      sunion keys.to_a
    end

    # This command is equal to SUNION, but instead of returning the resulting set, it is stored in destination.
    #
    # **Return value**: Integer, the number of elements in the resulting set.
    def sunionstore(destination, keys : Array(String)) : Int64
      integer_command(concat(["SUNIONSTORE", namespaced(destination)], namespaced(keys)))
    end

    # :ditto:
    def sunionstore(destination, *keys : String) : Int64
      sunionstore destination, keys.to_a
    end

    # BLPOP is a blocking list pop primitive.
    # It is the blocking version of LPOP because it blocks the connection when there
    # are no elements to pop from any of the given lists.
    # An element is popped from the head of the first list that is non-empty,
    # with the given keys being checked in the order that they are given.
    #
    # The timeout_in_seconds argument is interpreted as an integer value specifying the maximum number of seconds to block
    #
    # **Return value**: Array, specifically:
    # * An array of nils when no element could be popped and the timeout expired.
    # * An array of two-element arrays with the first element being the name of the key where an element was popped and the second element being the value of the popped element.
    #
    # Example:
    #
    # ```
    # redis.blpop(["myotherlist", "mylist"], 1) # => ["mylist", "hello"]
    # ```
    def blpop(keys, timeout_in_seconds)
      q = concat(["BLPOP"], namespaced(keys))
      q << timeout_in_seconds.to_s
      result = array_or_nil_command(q)

      return result unless result

      result[0] = without_namespace("#{result.first}")
      result
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
    # **Return value**: Array, specifically:
    # * An array of nils when no element could be popped and the timeout expired.
    # * An array of two-element arrays with the first element being the name of the key where an element was popped and the second element being the value of the popped element.
    #
    # Example:
    #
    # ```
    # redis.brpop(["myotherlist", "mylist"], 1) # => ["mylist", "world"]
    # ```
    def brpop(keys, timeout_in_seconds)
      q = concat(["BRPOP"], namespaced(keys))
      q << timeout_in_seconds.to_s
      result = array_or_nil_command(q)

      return result unless result

      result[0] = without_namespace("#{result.first}")
      result
    end

    # Atomically returns and removes the last element (tail) of the list stored at source,
    # and pushes the element at the first element (head) of the list stored at destination.
    #
    # **Return value**: String, the element being popped and pushed.
    def rpoplpush(source, destination)
      string_or_nil_command(["RPOPLPUSH", namespaced(source), namespaced(destination)])
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
    # **Return value**: String, the element being popped from source and pushed to destination.
    # If timeout is reached, nil is returned.
    #
    # Example:
    #
    # ```
    # redis.brpoplpush("source", "destination", 0)
    # ```
    def brpoplpush(source, destination, timeout_in_seconds = nil)
      q = ["BRPOPLPUSH", source.to_s, destination.to_s]
      if timeout_in_seconds
        q << timeout_in_seconds.to_s
      end
      string_or_nil_command(q)
    end

    # Sets field in the hash stored at key to value.
    #
    # **Return value**: Integer, specifically:
    # * 1 if field is a new field in the hash and value was set.
    # * 0 if field already exists in the hash and the value was updated.
    #
    # Example:
    #
    # ```
    # redis.hset("myhash", "a", "434")
    # ```
    def hset(key, field, value)
      integer_command(["HSET", namespaced(key), field.to_s, value.to_s])
    end

    # Returns the value associated with field in the hash stored at key.
    #
    # **Return value**: String, the value associated with field, or nil
    #
    # Example:
    #
    # ```
    # redis.hget("myhash", "a") # => "434"
    # ```
    def hget(key, field)
      string_or_nil_command(["HGET", namespaced(key), field.to_s])
    end

    # Returns all fields and values of the hash stored at key.
    #
    # **Return value**: Array(String) of fields and their values stored in the hash,
    # or an empty array when key does not exist.
    def hgetall(key)
      string_array_command(["HGETALL", namespaced(key)])
    end

    # Removes the specified fields from the hash stored at key.
    #
    # **Return value**: Integer, the number of fields that were removed from the hash,
    # not including specified but non existing fields.
    def hdel(key, field)
      integer_command(["HDEL", namespaced(key), field.to_s])
    end

    # Returns if field is an existing field in the hash stored at key.
    #
    # **Return value**: Integer, specifically:
    # * 1 if the hash contains field.
    # * 0 if the hash does not contain field, or key does not exist.
    def hexists(key, field)
      integer_command(["HEXISTS", namespaced(key), field.to_s])
    end

    # Increments the number stored at field in the hash stored at key by increment.
    #
    # **Return value**: Integer, the value at field after the increment operation.
    #
    # Example:
    #
    # ```
    # redis.hincrby("myhash", "field1", "3") # => 4
    # ```
    def hincrby(key, field, increment)
      integer_command(["HINCRBY", namespaced(key), field.to_s, increment.to_s])
    end

    # Increment the specified field of an hash stored at key,
    # and representing a floating point number, by the specified increment.
    #
    # **Return value**: String, the value at field after the increment operation.
    def hincrbyfloat(key, field, increment)
      string_command(["HINCRBYFLOAT", namespaced(key), field.to_s, increment.to_s])
    end

    # Returns all field names in the hash stored at key.
    #
    # **Return value**: Array(String) - list of fields in the hash, or an empty list when key does not exist.
    def hkeys(key)
      string_array_command(["HKEYS", namespaced(key)])
    end

    # Returns the number of fields contained in the hash stored at key.
    #
    # **Return value**: Integer, the number of fields in the hash, or 0 when key does not exist.
    def hlen(key)
      integer_command(["HLEN", namespaced(key)])
    end

    # Returns the values associated with the specified fields in the hash stored at key.
    #
    # **Return value**: Array(RedisValue), the list of values associated with the given fields, in the same order as they are requested.
    def hmget(key, fields : Array(String)) : Array(RedisValue) | Redis::Future
      string_array_command(concat(["HMGET", namespaced(key)], fields))
    end

    # :ditto:
    def hmget(key, *fields : String) : Array(RedisValue) | Redis::Future
      hmget key, fields.to_a
    end

    # Sets the specified fields to their respective values in the hash stored at key.
    #
    # **Return value**: "OK"
    def hmset(key, hash)
      q = ["HMSET", namespaced(key)] of RedisValue
      hash.each { |field, value| q << field.to_s << value.to_s }
      string_command(q)
    end

    # The SCAN command and the closely related commands SSCAN, HSCAN and ZSCAN are used in order to incrementally iterate over a collection of elements.
    #
    # **Options**:
    #
    # * match - It is possible to only iterate elements matching a given glob-style pattern, similarly to the behavior of the KEYS command that takes a pattern as only argument.
    # * count - While SCAN does not provide guarantees about the number of elements returned at every iteration, it is possible to empirically adjust the behavior of SCAN using the COUNT option.
    #
    # **Return value**: Array(String), two elements, a field and a value, for every returned element of the Hash.

    # ```
    # redis.hscan("myhash", 0)
    # redis.hscan("myhash", 0, "foo*")
    # redis.hscan("myhash", 0, "foo*", 1024)
    # ```
    def hscan(key, cursor, match = nil, count = nil)
      q = ["HSCAN", namespaced(key), cursor.to_s]
      q << "MATCH" << match.to_s if match
      q << "COUNT" << count.to_s if count
      string_array_command(q)
    end

    # Sets field in the hash stored at key to value, only if field does not yet exist.
    #
    # **Return value**: Integer, specifically:
    # * 1 if field is a new field in the hash and value was set.
    # * 0 if field already exists in the hash and no operation was performed.
    def hsetnx(key, field, value)
      integer_command(["HSETNX", namespaced(key), field.to_s, value.to_s])
    end

    # Returns all values in the hash stored at key.
    #
    # **Return value**: Array(String), the list of values in the hash, or an empty list when key does not exist.
    def hvals(key)
      string_array_command(["HVALS", namespaced(key)])
    end

    # Adds all the specified members with the specified scores to the sorted set stored at key.
    #
    # **Return value**: Integer, the number of elements added to the sorted sets, not including elements already existing for which the score was updated.
    #
    # Example:
    #
    # ```
    # redis.zadd("myzset", 1, "one")
    # redis.zadd("myzset", 2, "two", 3, "three")
    # ```
    def zadd(key, *scores_and_members)
      if scores_and_members.size % 2 > 0
        raise Error.new("zadd expects an array of scores mapped to members")
      end

      integer_command(concat(["ZADD", namespaced(key)], scores_and_members))
    end

    def zadd(key, scores_and_members : Array(RedisValue))
      if scores_and_members.size % 2 > 0
        raise Error.new("zadd expects an array of scores mapped to members")
      end

      integer_command(concat(["ZADD", namespaced(key)], scores_and_members))
    end

    # Returns the specified range of elements in the sorted set stored at key.
    #
    # **Options**:
    #
    # * with_scores - true to return the scores of the elements together with the elements.
    #
    # **Return value**: Array(String), list of elements in the specified range (optionally with their scores, in case the with_scores option is true).
    #
    # Example:
    #
    # ```
    # redis.zrange("myzset", 0, -1, with_scores: true) # => ["one", "1", "uno", "1", "two", "2", "three", "3"]
    # ```
    def zrange(key, start, stop, with_scores = false)
      q = ["ZRANGE", namespaced(key), start.to_s, stop.to_s]
      if with_scores
        q << "WITHSCORES"
      end
      string_array_command(q)
    end

    # Returns the sorted set cardinality (number of elements) of the sorted set stored at key.
    #
    # **Return value**: Integer, the cardinality (number of elements) of the sorted set, or 0 if key does not exist.
    def zcard(key)
      integer_command(["ZCARD", namespaced(key)])
    end

    # Returns the score of member in the sorted set at key.
    #
    # **Return value**: String, the score of member (a double precision floating point number).
    def zscore(key, member)
      string_or_nil_command(["ZSCORE", namespaced(key), member.to_s])
    end

    # Returns the number of elements in the sorted set at key with a score between min and max.
    #
    # **Return value**: Integer, the number of elements in the specified score range.
    def zcount(key, min, max)
      integer_command(["ZCOUNT", namespaced(key), min.to_s, max.to_s])
    end

    # When all the elements in a sorted set are inserted with the same score, in order to force lexicographical ordering, this command returns the number of elements in the sorted set at key with a value between min and max.
    #
    # **Return value**: Integer, the number of elements in the specified score range.
    def zlexcount(key, min, max)
      integer_command(["ZLEXCOUNT", namespaced(key), min.to_s, max.to_s])
    end

    # Increments the score of member in the sorted set stored at key by increment.
    #
    # **Return value**: String, the new score of member (a double precision floating point number represented as String).
    def zincrby(key, increment, member)
      string_command(["ZINCRBY", namespaced(key), increment.to_s, member.to_s])
    end

    # Removes the specified members from the sorted set stored at key.
    #
    # **Return value**: Integer, the number of members removed from the sorted set, not including non existing members.
    def zrem(key, member)
      integer_command(["ZREM", namespaced(key), member.to_s])
    end

    # Returns the rank of member in the sorted set stored at key, with the scores ordered from low to high.
    #
    # **Return value**:
    # * If member exists in the sorted set, Integer: the rank of member.
    # * If member does not exist in the sorted set or key does not exist: nil.
    def zrank(key, member)
      integer_or_nil_command(["ZRANK", namespaced(key), member.to_s])
    end

    # Returns the rank of member in the sorted set stored at key,
    # with the scores ordered from high to low.
    #
    # **Return value**:
    # * If member exists in the sorted set, Integer: the rank of member.
    # * If member does not exist in the sorted set or key does not exist: nil.
    def zrevrank(key, member)
      integer_or_nil_command(["ZREVRANK", namespaced(key), member.to_s])
    end

    # Computes the intersection of numkeys sorted sets given by the specified keys,
    # and stores the result in destination.
    #
    # **Options**:
    #
    # * weights - nil or Array(String): Using the WEIGHTS option, it is possible to specify a multiplication factor for each input sorted set.
    # * aggregate - With the AGGREGATE option, it is possible to specify how the results of the union are aggregated.
    #
    # **Return value**: Integer, the number of elements in the resulting sorted set at destination.
    #
    # Example:
    #
    # ```
    # redis.zinterstore("zset3", ["zset1", "zset2"], weights: [2, 3])
    # ```
    def zinterstore(destination, keys : Array, weights = nil, aggregate = nil)
      numkeys = keys.size
      q = concat(["ZINTERSTORE", namespaced(destination), numkeys.to_s], namespaced(keys))
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
    # **Return value**: Integer, the number of elements in the resulting sorted set at destination.
    def zunionstore(destination, keys : Array, weights = nil, aggregate = nil)
      numkeys = keys.size
      q = concat(["ZUNIONSTORE", namespaced(destination), numkeys.to_s], namespaced(keys))
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
      q = ["ZRANGEBYLEX", namespaced(key), min.to_s, max.to_s]
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
    # **Return value**: Array(String), the list of elements in the specified score range (optionally with their scores).
    def zrangebyscore(key, min, max, limit = nil, with_scores = false)
      q = ["ZRANGEBYSCORE", namespaced(key), min.to_s, max.to_s]
      if limit
        q << "LIMIT" << limit[0].to_s << limit[1].to_s
      end
      if with_scores
        q << "WITHSCORES"
      end
      string_array_command(q)
    end

    # Returns the specified range of elements in the sorted set stored at key.
    #
    # **Options**:
    #
    # * with_scores - true to return the scores of the elements together with the elements.
    #
    # **Return value**: Array(String), the list of elements in the specified range (optionally with their scores, in case the with_scores option is true).
    def zrevrange(key, start, stop, with_scores = false)
      q = ["ZREVRANGE", namespaced(key), start.to_s, stop.to_s]
      if with_scores
        q << "WITHSCORES"
      end

      string_array_command(q)
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
    def zrevrangebylex(key, min, max, limit = nil)
      q = ["ZREVRANGEBYLEX", namespaced(key), min.to_s, max.to_s]
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
    # **Return value**: Array(String), the list of elements in the specified score range (optionally with their scores).
    def zrevrangebyscore(key, min, max, limit = nil, with_scores = false)
      q = ["ZREVRANGEBYSCORE", namespaced(key), min.to_s, max.to_s]
      if limit
        q << "LIMIT" << limit[0].to_s << limit[1].to_s
      end
      if with_scores
        q << "WITHSCORES"
      end
      string_array_command(q)
    end

    # When all the elements in a sorted set are inserted with the same score,
    # in order to force lexicographical ordering, this command removes all
    # elements in the sorted set stored at key between the lexicographical range
    # specified by min and max.
    #
    # **Return value**: Integer, the number of elements removed.
    def zremrangebylex(key, min, max)
      integer_command(["ZREMRANGEBYLEX", namespaced(key), min.to_s, max.to_s])
    end

    # Removes all elements in the sorted set stored at key with rank between start and stop.
    #
    # **Return value**: Integer, the number of elements removed.
    def zremrangebyrank(key, start, stop)
      integer_command(["ZREMRANGEBYRANK", namespaced(key), start.to_s, stop.to_s])
    end

    # Removes all elements in the sorted set stored at key with a score
    # between min and max (inclusive).
    #
    # **Return value**: Integer, the number of elements removed.
    def zremrangebyscore(key, start, stop)
      integer_command(["ZREMRANGEBYSCORE", namespaced(key), start.to_s, stop.to_s])
    end

    # The SCAN command and the closely related commands SSCAN, HSCAN and ZSCAN are used in order to incrementally iterate over a collection of elements.
    #
    # **Options**:
    #
    # * match - It is possible to only iterate elements matching a given glob-style pattern, similarly to the behavior of the KEYS command that takes a pattern as only argument.
    # * count - While SCAN does not provide guarantees about the number of elements returned at every iteration, it is possible to empirically adjust the behavior of SCAN using the COUNT option.
    #
    # **Return value**: Array(String), contains two elements, a member and its associated score, for every returned element of the sorted set.
    #
    # Example:
    #
    # ```
    # redis.zscan("myzset", 0)
    # redis.zscan("myzset", 0, "foo*")
    # redis.zscan("myzset", 0, "foo*", 1024)
    # ```
    def zscan(key, cursor, match = nil, count = nil)
      q = ["ZSCAN", namespaced(key), cursor.to_s]
      q << "MATCH" << match.to_s if match
      q << "COUNT" << count.to_s if count
      string_array_command(q)
    end

    # Adds all the element arguments to the HyperLogLog data structure stored at
    # the variable name specified as first argument.
    #
    # **Return value**: Integer: 1 if at least 1 HyperLogLog internal register was altered. 0 otherwise.
    #
    # Example:
    #
    # ```
    # redis.pfadd("hll", "a", "b", "c", "d", "e", "f", "g") # => 1
    # ```
    def pfadd(key, values : Array(String)) : Int64
      integer_command(concat(["PFADD", namespaced(key)], values))
    end

    # :ditto:
    def pfadd(key, *values : String) : Int64
      pfadd key, values.to_a
    end

    # Merge multiple HyperLogLog values into an unique value that will
    # approximate the cardinality of the union of the observed Sets of the
    # source HyperLogLog structures.
    def pfmerge(keys : Array(String))
      string_command(concat(["PFMERGE"], namespaced(keys)))
    end

    # :ditto:
    def pfmerge(*keys : String)
      pfmerge keys.to_a
    end

    # When called with a single key, returns the approximated cardinality computed
    # by the HyperLogLog data structure stored at the specified variable,
    # which is 0 if the variable does not exist.
    #
    # **Return value**: Integer, the approximated number of unique elements
    # observed via PFADD.
    def pfcount(keys : Array(String)) : Int64
      integer_command(concat(["PFCOUNT"], namespaced(keys)))
    end

    # :ditto:
    def pfcount(*keys : String) : Int64
      pfcount keys.to_a
    end

    # EVAL and EVALSHA are used to evaluate scripts using the Lua interpreter
    # built into Redis starting from version 2.6.0.
    #
    # **Return value**: Array(String), depends on the executed script
    #
    # Example:
    #
    # ```
    # redis.eval("return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}", ["key1", "key2"], ["first art", "second arg"])
    # ```
    def eval(script : String, keys = [] of RedisValue, args = [] of RedisValue)
      string_array_command(concat(["EVAL", script, keys.size.to_s], keys, args))
    end

    # EVAL and EVALSHA are used to evaluate scripts using the Lua interpreter
    # built into Redis starting from version 2.6.0.
    #
    # **Return value**: Array(String), depends on the executed script
    def evalsha(sha1, keys = [] of RedisValue, args = [] of RedisValue)
      string_array_command(concat(["EVALSHA", sha1.to_s, keys.size.to_s], keys, args))
    end

    # Load a script into the scripts cache, without executing it.
    #
    # **Return value**: String, the SHA1 digest of the script
    # added into the script cache.
    #
    # Example:
    #
    # ```
    # redis.script_load("return {KEYS[1],ARGV[1]}") # => "a191862bfe0bd3bec995befcd060582bf4bdbd77"
    # ```
    def script_load(script : String)
      string_command(["SCRIPT", "LOAD", script])
    end

    # Kills the currently executing Lua script, assuming no write operation was
    # yet performed by the script.
    #
    # **Return value**: "OK"
    def script_kill
      string_command(["SCRIPT", "KILL"])
    end

    # Returns information about the existence of the scripts in the script cache.
    #
    # **Return value**: The command returns an array of integers that correspond
    # to the specified SHA1 digest arguments.
    # For every corresponding SHA1 digest of a script that actually exists
    # in the script cache, an 1 is returned, otherwise 0 is returned.
    def script_exists(sha1_array : Array(Reference))
      integer_array_command(concat(["SCRIPT", "EXISTS"], sha1_array))
    end

    # Flush the current database.
    #
    # **Return value**: "OK"
    def flushdb
      string_command(["FLUSHDB"])
    end

    # Flush all databases.
    #
    # **Return value**: "OK"
    def flushall
      string_command(["FLUSHALL"])
    end

    # Flush the Lua scripts cache.
    #
    # **Return value**: "OK"
    def script_flush
      string_command(["SCRIPT", "FLUSH"])
    end

    # Set a timeout on key.
    #
    # **Return value**: Integeger, specifically:
    # * 1 if the timeout was set.
    # * 0 if key does not exist or the timeout could not be set.
    #
    # Example:
    #
    # ```
    # redis.expire("temp", 2)
    # ```
    def expire(key, seconds)
      integer_command(["EXPIRE", namespaced(key), seconds.to_s])
    end

    # This command works exactly like EXPIRE but the time to live of the key is
    # specified in milliseconds instead of seconds.
    #
    # **Return value**: Integeger, specifically:
    # * 1 if the timeout was set.
    # * 0 if key does not exist or the timeout could not be set.
    def pexpire(key, milis)
      integer_command(["PEXPIRE", namespaced(key), milis.to_s])
    end

    # EXPIREAT has the same effect and semantic as EXPIRE, but instead of
    # specifying the number of seconds representing the TTL (time to live),
    # it takes an absolute Unix timestamp (seconds since January 1, 1970).
    #
    # **Return value**: Integeger, specifically:
    # * 1 if the timeout was set.
    # * 0 if key does not exist or the timeout could not be set.
    def expireat(key, unix_date)
      integer_command(["EXPIREAT", namespaced(key), unix_date.to_s])
    end

    # PEXPIREAT has the same effect and semantic as EXPIREAT, but the Unix time
    # at which the key will expire is specified in milliseconds instead of seconds.
    #
    # **Return value**: Integeger, specifically:
    # * 1 if the timeout was set.
    # * 0 if key does not exist or the timeout could not be set.
    def pexpireat(key, unix_date_in_millis)
      integer_command(["PEXPIREAT", namespaced(key), unix_date_in_millis.to_s])
    end

    # Remove the existing timeout on key, turning the key from volatile
    # (a key with an expire set) to persistent (a key that will never expire
    # as no timeout is associated).
    #
    # **Return value**: Integer, specifically:
    # * 1 if the timeout was removed.
    # * 0 if key does not exist or does not have an associated timeout.
    def persist(key)
      integer_command(["PERSIST", namespaced(key)])
    end

    # Returns the remaining time to live of a key that has a timeout.
    #
    # **Return value**: Integer: TTL in seconds, or a negative value in order to
    # signal an error (see the description above).
    def ttl(key)
      integer_command(["TTL", namespaced(key)])
    end

    # Like TTL this command returns the remaining time to live of a key that has
    # an expire set, with the sole difference that TTL returns the amount of
    # remaining time in seconds while PTTL returns it in milliseconds.
    #
    # **Return value**: Integer, the TTL in milliseconds, or a negative value in order to signal an error.
    def pttl(key)
      integer_command(["PTTL", namespaced(key)])
    end

    # Returns the string representation of the type of the value stored at key.
    #
    # **Return value**: String, the type of key, or none when key does not exist.
    #
    # Example:
    #
    # ```
    # redis.set("foo", 3)
    # redis.type("foo") # => "string"
    # ```
    def type(key)
      string_command(["TYPE", namespaced(key)])
    end

    # Subscribes to channels and enters a subscription loop, waiting for events.
    #
    # The method yields to the given block and passes a Subscription object, on
    # which you can set your callbacks for the event subscription.
    #
    # The subscription loop will end once you unsubscribe.
    #
    # See also: `Subscription` class
    # See also: Example `subscribe.cr`
    #
    # Example:
    #
    # ```
    # redis.subscribe("mychannel") do |on|
    #   on.message do |channel, message|
    #     puts "Received message: #{message}"
    #     if message == "goodbye pal"
    #       redis.unsubscribe
    #     end
    #   end
    # end
    # ```
    def subscribe(*channels, &callback_setup_block : Subscription ->)
      # Can be called only outside a subscription block
      if already_in_subscription_loop?
        raise Redis::Error.new("Must call subscribe without a subscription block when already inside a subscription loop")
      end

      subscription = Subscription.new
      # Allow the caller to populate the subscription with his callbacks.
      callback_setup_block.call(subscription)

      @strategy = Redis::Strategy::SubscriptionLoop.new(connection, subscription)

      subscribe(*channels)
    end

    # Subscribes to more channels while already being in a subscription loop.
    def subscribe(channels : Array(String)) : Void
      # Can be called only inside a subscription block
      unless already_in_subscription_loop?
        raise Redis::Error.new("Must call subscribe with a subscription block")
      end

      void_command(concat(["SUBSCRIBE"], channels))
    end

    # :ditto:
    def subscribe(*channels : String)
      subscribe channels.to_a
    end

    # Subscribes to channel patterns and enters a subscription loop, waiting for events.
    #
    # The method yields to the given block and passes a Subscription object, on
    # which you can set your callbacks for the event subscription.
    #
    # The subscription loop will end once you unsubscribe.
    def psubscribe(*channel_patterns, &callback_setup_block : Subscription ->)
      # Can be called only outside a subscription block
      if already_in_subscription_loop?
        raise Redis::Error.new("Must call psubscribe without a subscription block when inside a subscription loop")
      end

      subscription = Subscription.new
      # Allow the caller to populate the subscription with his callbacks.
      callback_setup_block.call(subscription)

      @strategy = Redis::Strategy::SubscriptionLoop.new(connection, subscription)

      psubscribe(*channel_patterns)
    end

    # Subscribes to more channel patterns while already being in a subscription loop.
    def psubscribe(channel_patterns : Array(String))
      # Can be called only inside a subscription block
      unless already_in_subscription_loop?
        raise Redis::Error.new("Must call psubscribe with a subscription block")
      end

      void_command(concat(["PSUBSCRIBE"], channel_patterns))
    end

    def psubscribe(*channel_patterns)
      psubscribe channel_patterns.to_a
    end

    private def already_in_subscription_loop?
      strategy.is_a? Redis::Strategy::SubscriptionLoop
    end

    # Unsubscribes the client from the given channels, or from all of them if none is given.
    def unsubscribe(channels : Array(String)) : Nil
      void_command(concat(["UNSUBSCRIBE"], channels))
    end

    # :ditto:
    def unsubscribe(*channels)
      unsubscribe channels.to_a
    end

    # Unsubscribes the client from the given patterns, or from all of them if none is given.
    def punsubscribe(channel_patterns : Array(String))
      void_command(concat(["PUNSUBSCRIBE"], channel_patterns))
    end

    # :ditto:
    def punsubscribe(*channel_patterns)
      punsubscribe channel_patterns.to_a
    end

    # Posts a message to the given channel.
    #
    # **Return value**: Integer, the number of clients that received the message.
    #
    # Example:
    #
    # ```
    # redis.publish("mychannel", "some message")
    # ```
    def publish(channel, message)
      integer_command(["PUBLISH", channel.to_s, message.to_s])
    end

    # Marks the given keys to be watched for conditional execution of a transaction.
    #
    # **Return value**: "OK"
    def watch(keys : Array(String))
      string_command(concat(["WATCH"], namespaced(keys)))
    end

    def watch(*keys)
      watch keys.to_a
    end

    # Flushes all the previously watched keys for a transaction.
    #
    # **Return value**: "OK"
    def unwatch
      string_command(["UNWATCH"])
    end

    # The INFO command returns information and statistics about the server.
    #
    # **Return value**: A hash with the server information
    def info(section : String? = nil)
      arr = ["INFO"]
      arr << section if section
      bulk = string_command(arr)
      results = Hash(String, String).new
      bulk.split("\r\n").each do |line|
        next if line.empty? || line[0] == '#'
        key, val = line.split(":")
        results[key] = val
      end
      results
    end

    # Returns the number of references of the value associated
    # with the specified key.
    #
    # **Return value**: Integer: returns the number of references
    # of the value associated with the specified key.
    def object_refcount(key)
      integer_or_nil_command(["OBJECT", "REFCOUNT", namespaced(key)])
    end

    # Returns the kind of internal representation used in order to store
    # the value associated with a key.
    #
    # **Return value**: String: returns the kind of internal representation
    # used in order to store the value associated with a key.
    def object_encoding(key)
      string_or_nil_command(["OBJECT", "ENCODING", namespaced(key)])
    end

    # Returns the number of seconds since the object stored at the specified key
    # is idle (not requested by read or write operations).
    #
    # **Return value**: Integer: returns the number of seconds
    # since the object stored at the specified key is idle
    # (not requested by read or write operations).
    def object_idletime(key)
      integer_or_nil_command(["OBJECT", "IDLETIME", namespaced(key)])
    end

    # Adds the specified geospatial items (latitude, longitude, name) to the specified key.
    #
    # **Return value**: Integer: The number of elements added to the sorted set, not including elements already existing for which the score was updated.
    def geoadd(key, longitude, latitude, place)
      integer_command(["GEOADD", namespaced(key), longitude.to_s, latitude.to_s, place.to_s])
    end

    # Return the distance between two members in the geospatial index represented by the sorted set.
    #
    # **Return value**: String: returns the distance as a double (represented as a string) in the specified unit,
    # or NULL if one or both the elements are missing
    def geodist(key, member1, member2, unit = nil)
      q = ["GEODIST", namespaced(key), member1.to_s, member2.to_s]
      q << unit.to_s if unit
      string_or_nil_command(q)
    end

    # Return valid Geohash strings representing the position of one or more elements in a sorted set value representing a geospatial index
    #
    # **Return value**: Array(String): returns an array where each element is the Geohash corresponding to each
    # member name passed as argument to the command
    def geohash(key, *args)
      q = ["GEOHASH", namespaced(key)]
      args.each do |arg|
        q << arg.to_s
      end
      string_array_command(q)
    end

    # Return the positions (longitude,latitude) of all the specified members of the geospatial index represented by the sorted set at key
    #
    # **Return value**: Array(String): returns an array where each element is a two elements array representing
    # longitude and latitude (x,y) of each member name passed as argument to the command
    def geopos(key, *args)
      q = ["GEOPOS", namespaced(key)]
      args.each do |arg|
        q << arg.to_s
      end
      string_array_command(q)
    end

    # Return the members of a sorted set populated with geospatial information using GEOADD, which are within the borders
    # of the area specified with the center location and the maximum distance from the center (the radius).
    #
    # **Return value**: Array(String): Returns a simple array or array of arrays, depending on the options passed
    # https://redis.io/commands/georadius#return-value
    def georadius(key, longitude, latitude, radius, unit, withcoord = nil, withdist = nil, withhash = nil, count = nil, sort = nil)
      q = ["GEORADIUS", namespaced(key), longitude.to_s, latitude.to_s, radius.to_s, unit.to_s]
      q << "WITHCOORD" if withcoord
      q << "WITHDIST" if withdist
      q << "WITHHASH" if withhash
      q << count.to_s if count
      q << sort.to_s if sort
      string_array_command(q)
    end

    # Exactly like GEORADIUS with the sole difference that instead of taking, as the center of the area to query, a longitude
    # and latitude value, it takes the name of a member already existing inside the geospatial index represented by the sorted set
    #
    # **Return value**: Array(String): Returns a simple array or array of arrays, depending on the options passed
    # https://redis.io/commands/georadius#return-value
    def georadiusbymember(key, member, radius, unit, withcoord = nil, withdist = nil, withhash = nil, count = nil, sort = nil)
      q = ["GEORADIUSBYMEMBER", namespaced(key), member.to_s, radius.to_s, unit.to_s]
      q << "WITHCOORD" if withcoord
      q << "WITHDIST" if withdist
      q << "WITHHASH" if withhash
      q << count.to_s if count
      q << sort.to_s if sort
      string_array_command(q)
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

    private def namespaced(keys : (Array(String) | Tuple(String, String)))
      keys.map { |key| namespaced(key) }
    end

    private def namespaced(key : (String | Symbol | Int32))
      return key.to_s if @namespace == ""

      [@namespace, key.to_s].join("::")
    end

    private def without_namespace(key : String)
      key.to_s.gsub(namespaced(""), "").as(RedisValue)
    end

    private def array_without_namespace(keys : (Array(Redis::RedisValue) | Int32 | Int64 | String | Nil))
      return keys unless keys.is_a?(Array(RedisValue))

      keys.map { |key| without_namespace("#{key}") }
    end
  end
end
