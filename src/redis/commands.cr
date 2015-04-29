class Redis
  module Commands
    def echo(string)
      string_command(["ECHO", string.to_s])
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

    def watch(*keys)
      string_command(concat(["WATCH"], keys))
    end

    def unwatch
      string_command(["UNWATCH"])
    end

    def ping
      string_command(["PING"])
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

      command(q) as Array(RedisValue) | Int64 | Redis::Future
    end

    def mget(*keys)
      string_array_command(concat(["MGET"] of RedisValue, keys))
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
      integer_command(["STRLEN", key.to_s]) as Int64 | Future
    end

    def getrange(key, start_index, end_index)
      string_command(["GETRANGE", key.to_s, start_index.to_s, end_index.to_s]) as String | Future
    end

    def setrange(key, start_index, s)
      integer_command(["SETRANGE", key.to_s, start_index.to_s, s.to_s]) as Int64 | Future
    end

  end
end
