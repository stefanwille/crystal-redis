require "./spec_helper"

# A poor man's sort for an array of redis values.
#
# I don't know how to do this better within Crystal's type system.
private def sort(a)
  unless a.is_a? Array(Redis::RedisValue)
    raise "Cannot sort this: #{a.class}"
  end

  convert_to_string_array(a).sort
end

private def convert_to_string_array(a)
  a.map { |item| item.to_s }
end

# Same as `sort` except sorting feature
private def array(a) : Array(String)
  (a.as(Array(Redis::RedisValue))).map(&.to_s)
rescue
  raise "Cannot convert to Array(Redis::RedisValue): #{a.class}"
end

ENV["CI"] ||= "false"

describe Redis do
  describe ".new" do
    it "connects to default host and port" do
      redis = Redis.new
    end

    it "connects to specific port and host / disconnects" do
      redis = Redis.new(host: "localhost", port: 6379)
    end

    it "connects to a specific database" do
      redis = Redis.new(host: "localhost", port: 6379, database: 1)
      redis.url.should eq("redis://localhost:6379/1")
    end

    it "connects to Unix domain sockets" do
      if ENV["CI"] != "true"
        redis = Redis.new(unixsocket: "/tmp/redis.sock")
        redis.url.should eq("redis:///tmp/redis.sock/0")
        redis.ping.should eq "PONG"
      end
    end

    context "when url argument is given" do
      it "connects using given URL" do
        redis = Redis.new(url: "redis://127.0.0.1", host: "host.to.be.ignored", port: 1234)
        redis.url.should eq("redis://127.0.0.1:6379/0")
      end
    end

    context "when url argument with trailing slash is given" do
      it "connects using given URL" do
        redis = Redis.new(url: "redis://127.0.0.1/")
        redis.url.should eq("redis://127.0.0.1:6379/0")
      end
    end

    describe "#close" do
      it "closes the connection" do
        redis = Redis.new
        redis.close
      end

      it "tolerates a duplicate call" do
        redis = Redis.new
        redis.close
        redis.close
      end
    end
  end

  describe ".open" do
    it "connects to the Redis server, yields its block and disconnects" do
      Redis.open do |redis|
        redis.url.should eq("redis://localhost:6379/0")
      end
    end

    it "connects to the Redis using given url, yields its block and disconnects" do
      Redis.open(url: "redis://127.0.0.1") do |redis|
        redis.url.should eq("redis://127.0.0.1:6379/0")
      end
    end
  end

  it "#ping" do
    Redis.open do |redis|
      redis.ping.should eq("PONG")
    end
  end

  it "#echo" do
    Redis.open do |redis|
      redis.echo("Ciao").should eq("Ciao")
    end
  end

  it "#quit" do
    Redis.open do |redis|
      redis.quit.should eq("OK")
    end
  end

  it "#select" do
    Redis.open do |redis|
      redis.select(0).should eq("OK")
    end
  end

  it "#auth" do
    Redis.open do |redis|
      begin
        redis.auth("some-password").should eq("OK")
      rescue e : Redis::Error
        e.message.should eq("RedisError: ERR Client sent AUTH, but no password is set")
      end
    end
  end

  describe "keys" do
    redis = Redis.new

    it "#del" do
      redis.set("foo", "test")
      redis.del("foo")
      redis.get("foo").should eq(nil)
    end

    it "converts keys to strings" do
      redis.set(:foo, "hello")
      redis.set(123456, 7)
      redis.get("foo").should eq("hello")
      redis.get("123456").should eq("7")
    end

    it "#rename" do
      redis.del("foo", "bar")
      redis.set("foo", "test")
      redis.rename("foo", "bar")
      redis.get("bar").should eq("test")
    end

    it "#renamenx" do
      redis.set("foo", "Hello")
      redis.set("bar", "world")
      redis.renamenx("foo", "bar").should eq(0)
      redis.get("bar").should eq("world")
    end

    it "#randomkey" do
      redis.set("foo", "Hello")
      redis.randomkey.should_not be_nil
    end

    it "#exists" do
      redis.del("foo")
      redis.exists("foo").should eq(0)
      redis.set("foo", "test")
      redis.exists("foo").should eq(1)
    end

    it "#keys" do
      redis.set("callmemaybe", 1)
      redis.keys("callmemaybe").should eq(["callmemaybe"])
    end

    describe "#sort" do
      it "sorts the container" do
        redis.del("mylist")
        redis.rpush("mylist", "1", "3", "2")
        redis.sort("mylist").should eq(["1", "2", "3"])
        redis.sort("mylist", order: "DESC").should eq(["3", "2", "1"])
      end

      it "limit" do
        redis.del("mylist")
        redis.rpush("mylist", "1", "3", "2")
        redis.sort("mylist", limit: [1, 2]).should eq(["2", "3"])
      end

      it "by" do
        redis.del("mylist", "objects", "weights")
        redis.rpush("mylist", "1", "3", "2")
        redis.mset({"weight_1" => 1, "weight_2" => 2, "weight_3" => 3})
        redis.sort("mylist", by: "weights_*").should eq(["1", "2", "3"])
      end

      it "alpha" do
        redis.del("mylist")
        redis.rpush("mylist", "c", "a", "b")
        redis.sort("mylist", alpha: true).should eq(["a", "b", "c"])
      end

      it "store" do
        redis.del("mylist", "destination")
        redis.rpush("mylist", "1", "3", "2")
        redis.sort("mylist", store: "destination")
        redis.lrange("destination", 0, 2).should eq(["1", "2", "3"])
      end
    end

    it "#dump / #restore" do
      Redis.open do |redis|
        redis.set("foo", "9")
        serialized_value = redis.dump("foo")
        # puts "**** ser: #{serialized_value.size}"
        # redis.del("foo")
        # redis.restore("foo", 0, serialized_value).should eq("OK")
        # redis.get("foo").should eq("9")
        # redis.ttl("foo").should eq(-1)
      end
    end
  end

  describe "strings" do
    redis = Redis.new

    it "#set / #get" do
      redis.set("foo", "test")
      redis.get("foo").should eq("test")
    end

    it "#set options" do
      redis.set("foo", "test", ex: 7)
      redis.ttl("foo").should eq(7)
    end

    it "#mget" do
      redis.set("foo1", "test1")
      redis.set("foo2", "test2")
      redis.mget("foo1", "foo2").should eq(["test1", "test2"])
      redis.mget(["foo2", "foo1"]).should eq(["test2", "test1"])
    end

    it "#mset" do
      redis.mset({"foo1" => "bar1", "foo2" => "bar2"})
      redis.get("foo1").should eq("bar1")
      redis.get("foo2").should eq("bar2")
    end

    it "#getset" do
      redis.set("foo", "old")
      redis.getset("foo", "new").should eq("old")
      redis.get("foo").should eq("new")
    end

    it "#setex" do
      redis.setex("foo", 3, "setexed")
      redis.get("foo").should eq("setexed")
    end

    it "#psetex" do
      redis.psetex("foo", 3000, "psetexed")
      redis.get("foo").should eq("psetexed")
    end

    it "#setnx" do
      redis.del("foo")
      redis.setnx("foo", "setnxed").should eq(1)
      redis.get("foo").should eq("setnxed")
      redis.setnx("foo", "setnxed2").should eq(0)
      redis.get("foo").should eq("setnxed")
    end

    it "#msetnx" do
      redis.del("key1", "key2", "key3")
      redis.msetnx({"key1": "hello", "key2": "there"}).should eq(1)
      redis.get("key1").should eq("hello")
      redis.get("key2").should eq("there")
      redis.msetnx({"key2": "keep", "key3": "singing"}).should eq(0)
      redis.get("key1").should eq("hello")
      redis.get("key2").should eq("there")
      redis.get("key3").should eq(nil)
    end

    it "#incr" do
      redis.set("foo", "3")
      redis.incr("foo").should eq(4)
    end

    it "#decr" do
      redis.set("foo", "3")
      redis.decr("foo").should eq(2)
    end

    it "#incrby" do
      redis.set("foo", "10")
      redis.incrby("foo", 4).should eq(14)
    end

    it "#decrby" do
      redis.set("foo", "10")
      redis.decrby("foo", 4).should eq(6)
    end

    it "#incrbyfloat" do
      redis.set("foo", "10")
      redis.incrbyfloat("foo", 2.5).should eq("12.5")
    end

    it "#append" do
      redis.set("foo", "hello")
      redis.append("foo", " world")
      redis.get("foo").should eq("hello world")
    end

    it "#strlen" do
      redis.set("foo", "Hello world")
      redis.strlen("foo").should eq(11)
      redis.del("foo")
      redis.strlen("foo").should eq(0)
    end

    it "#getrange" do
      redis.set("foo", "This is a string")
      redis.getrange("foo", 0, 3).should eq("This")
      redis.getrange("foo", -3, -1).should eq("ing")
    end

    it "#setrange" do
      redis.set("foo", "Hello world")
      redis.setrange("foo", 6, "Redis").should eq(11)
      redis.get("foo").should eq("Hello Redis")
    end

    describe "#scan" do
      it "no options" do
        redis.set("foo", "Hello world")
        new_cursor, keys = redis.scan(0)
        new_cursor = new_cursor.as(String)
        new_cursor.to_i.should be > 0
        keys.is_a?(Array).should be_true
      end

      it "with match" do
        redis.set("scan.match1", "1")
        redis.set("scan.match2", "2")
        new_cursor, keys = redis.scan(0, "scan.match*")
        new_cursor = new_cursor.as(String)
        new_cursor.to_i.should be > 0
        keys.is_a?(Array).should be_true
        # Here `keys.size` should be 0 or 1 or 2, but I don't know how to test it.
      end

      it "with match and count" do
        redis.set("scan.match1", "1")
        redis.set("scan.match2", "2")
        new_cursor, keys = redis.scan(0, "scan.match*", 1)
        new_cursor = new_cursor.as(String)
        new_cursor.to_i.should be > 0
        keys.is_a?(Array).should be_true
        # Here `keys.size` should be 0 or 1, but I don't know how to test it.
      end

      it "with match and count at once" do
        redis.set("scan.match1", "1")
        redis.set("scan.match2", "2")
        # assumes that current Redis instance has at most 10M entries
        new_cursor, keys = redis.scan(0, "scan.match*", 10_000_000)
        new_cursor.should eq("0")
        array(keys).sort.should eq(["scan.match1", "scan.match2"])
      end
    end
  end

  describe "bit operations" do
    redis = Redis.new

    it "#bitcount" do
      redis.set("foo", "foobar")
      redis.bitcount("foo", 0, 0).should eq(4)
      redis.bitcount("foo", 1, 1).should eq(6)
    end

    it "#bitop" do
      redis.set("key1", "foobar")
      redis.set("key2", "abcdef")
      redis.bitop("and", "dest", "key1", "key2").should eq(6)
      redis.get("dest").should eq("`bc`ab")
    end

    it "#bitpos" do
      redis.set("mykey", "0")
      redis.bitpos("mykey", 1).should eq(2)
    end

    it "#getbit / #setbit" do
      redis.del("mykey")
      redis.setbit("mykey", 7, 1).should eq(0)
      redis.getbit("mykey", 0).should eq(0)
      redis.getbit("mykey", 7).should eq(1)
      redis.getbit("mykey", 100).should eq(0)
    end
  end

  describe "lists" do
    redis = Redis.new

    it "#rpush / #lrange" do
      redis.del("mylist")
      redis.rpush("mylist", "hello").should eq(1)
      redis.rpush("mylist", "world").should eq(2)
      redis.lrange("mylist", 0, 1).should eq(["hello", "world"])
      redis.rpush("mylist", "snip", "snip").should eq(4)
    end

    it "#lpush" do
      redis.del("mylist")
      redis.lpush("mylist", "hello").should eq(1)
      redis.lpush("mylist", ["world"]).should eq(2)
      redis.lrange("mylist", 0, 1).should eq(["world", "hello"])
      redis.lpush("mylist", "snip", "snip").should eq(4)
    end

    it "#lpushx" do
      redis.del("mylist")
      redis.lpushx("mylist", "hello").should eq(0)
      redis.lrange("mylist", 0, 1).should eq([] of Redis::RedisValue)
      redis.lpush("mylist", "hello")
      redis.lpushx("mylist", "world").should eq(2)
      redis.lrange("mylist", 0, 1).should eq(["world", "hello"])
    end

    it "#rpushx" do
      redis.del("mylist")
      redis.rpushx("mylist", "hello").should eq(0)
      redis.lrange("mylist", 0, 1).should eq([] of Redis::RedisValue)
      redis.rpush("mylist", "hello")
      redis.rpushx("mylist", "world").should eq(2)
      redis.lrange("mylist", 0, 1).should eq(["hello", "world"])
    end

    it "#lrem" do
      redis.del("mylist")
      redis.rpush("mylist", "hello")
      redis.rpush("mylist", "my")
      redis.rpush("mylist", "world")
      redis.lrem("mylist", 1, "my").should eq(1)
      redis.lrange("mylist", 0, 1).should eq(["hello", "world"])
      redis.lrem("mylist", 0, "world").should eq(1)
      redis.lrange("mylist", 0, 1).should eq(["hello"])
    end

    it "#llen" do
      redis.del("mylist")
      redis.lpush("mylist", "hello")
      redis.lpush("mylist", "world")
      redis.llen("mylist").should eq(2)
    end

    it "#lset" do
      redis.del("mylist")
      redis.rpush("mylist", "hello")
      redis.rpush("mylist", "world")
      redis.lset("mylist", 0, "goodbye").should eq("OK")
      redis.lrange("mylist", 0, 1).should eq(["goodbye", "world"])
    end

    it "#lindex" do
      redis.del("mylist")
      redis.rpush("mylist", "hello")
      redis.rpush("mylist", "world")
      redis.lindex("mylist", 0).should eq("hello")
      redis.lindex("mylist", 1).should eq("world")
      redis.lindex("mylist", 2).should eq(nil)
    end

    it "#lpop" do
      redis.del("mylist")
      redis.rpush("mylist", "hello")
      redis.rpush("mylist", "world")
      redis.lpop("mylist").should eq("hello")
      redis.lpop("mylist").should eq("world")
      redis.lpop("mylist").should eq(nil)
    end

    it "#rpop" do
      redis.del("mylist")
      redis.rpush("mylist", "hello")
      redis.rpush("mylist", "world")
      redis.rpop("mylist").should eq("world")
      redis.rpop("mylist").should eq("hello")
      redis.rpop("mylist").should eq(nil)
    end

    it "#linsert" do
      redis.del("mylist")
      redis.rpush("mylist", "hello")
      redis.rpush("mylist", "world")
      redis.linsert("mylist", :before, "world", "dear").should eq(3)
      redis.lrange("mylist", 0, 2).should eq(["hello", "dear", "world"])
    end

    it "#blpop" do
      redis.del("mylist")
      redis.del("myotherlist")
      redis.rpush("mylist", "hello", "world")
      redis.blpop(["myotherlist", "mylist"], 1).should eq(["mylist", "hello"])
    end

    it "#ltrim" do
      redis.del("mylist")
      redis.rpush("mylist", "hello", "good", "world")
      redis.ltrim("mylist", 0, 0).should eq("OK")
      redis.lrange("mylist", 0, 2).should eq(["hello"])
    end

    it "#brpop" do
      redis.del("mylist")
      redis.del("myotherlist")
      redis.rpush("mylist", "hello", "world")
      redis.brpop(["myotherlist", "mylist"], 1).should eq(["mylist", "world"])
    end

    it "#rpoplpush" do
      redis.del("source")
      redis.del("destination")
      redis.rpush("source", "a", "b", "c")
      redis.rpush("destination", "1", "2", "3")
      redis.rpoplpush("source", "destination")
      redis.lrange("source", 0, 4).should eq(["a", "b"])
      redis.lrange("destination", 0, 4).should eq(["c", "1", "2", "3"])
    end

    it "#brpoplpush" do
      redis.del("source")
      redis.del("destination")
      redis.rpush("source", "a", "b", "c")
      redis.rpush("destination", "1", "2", "3")
      redis.brpoplpush("source", "destination", 0)
      redis.lrange("source", 0, 4).should eq(["a", "b"])
      redis.lrange("destination", 0, 4).should eq(["c", "1", "2", "3"])
    end
  end

  describe "sets" do
    redis = Redis.new

    it "#sadd / #smembers" do
      redis.del("myset")
      redis.sadd("myset", "Hello").should eq(1)
      redis.sadd("myset", "World").should eq(1)
      redis.sadd("myset", "World").should eq(0)
      redis.sadd("myset", ["Foo", "Bar"]).should eq(2)
      sort(redis.smembers("myset")).should eq(["Bar", "Foo", "Hello", "World"])
    end

    it "#scard" do
      redis.del("myset")
      redis.sadd("myset", "Hello", "World")
      redis.scard("myset").should eq(2)
    end

    it "#sismember" do
      redis.del("key1")
      redis.sadd("key1", "a")
      redis.sismember("key1", "a").should eq(1)
      redis.sismember("key1", "b").should eq(0)
    end

    it "#srem" do
      redis.del("myset")
      redis.sadd("myset", "Hello", "World")
      redis.srem("myset", "Hello").should eq(1)
      redis.smembers("myset").should eq(["World"])

      redis.sadd("myset", ["Hello", "World", "Foo"])
      redis.srem("myset", ["Hello", "Foo"]).should eq(2)
      redis.smembers("myset").should eq(["World"])
    end

    it "#sdiff" do
      redis.del("key1", "key2")
      redis.sadd("key1", "a", "b", "c")
      redis.sadd("key2", "c", "d", "e")
      sort(redis.sdiff("key1", "key2")).should eq(["a", "b"])
    end

    it "#spop" do
      redis.del("myset")
      redis.sadd("myset", "one")
      redis.spop("myset").should eq("one")
      redis.smembers("myset").should eq([] of Redis::RedisValue)
      # Redis 3.0 should have received the "count" argument, but hasn't.
      #
      # redis.sadd("myset", "one", "two")
      # sort(redis.spop("myset", count: 2)).should eq(["one", "two"])

      redis.del("myset")
      redis.spop("myset").should eq(nil)
    end

    it "#sdiffstore" do
      redis.del("key1", "key2", "destination")
      redis.sadd("key1", "a", "b", "c")
      redis.sadd("key2", "c", "d", "e")
      redis.sdiffstore("destination", "key1", "key2").should eq(2)
      sort(redis.smembers("destination")).should eq(["a", "b"])
    end

    it "#sinter" do
      redis.del("key1", "key2")
      redis.sadd("key1", "a", "b", "c")
      redis.sadd("key2", "c", "d", "e")
      redis.sinter("key1", "key2").should eq(["c"])
    end

    it "#sinterstore" do
      redis.del("key1", "key2", "destination")
      redis.sadd("key1", "a", "b", "c")
      redis.sadd("key2", "c", "d", "e")
      redis.sinterstore("destination", "key1", "key2").should eq(1)
      redis.smembers("destination").should eq(["c"])
    end

    it "#sunion" do
      redis.del("key1", "key2")
      redis.sadd("key1", "a", "b")
      redis.sadd("key2", "c", "d")
      sort(redis.sunion("key1", "key2")).should eq(["a", "b", "c", "d"])
    end

    it "#sunionstore" do
      redis.del("key1", "key2", "destination")
      redis.sadd("key1", "a", "b")
      redis.sadd("key2", "c", "d")
      redis.sunionstore("destination", "key1", "key2").should eq(4)
      sort(redis.smembers("destination")).should eq(["a", "b", "c", "d"])
    end

    it "#smove" do
      redis.del("key1", "key2", "destination")
      redis.sadd("key1", "a", "b")
      redis.sadd("key2", "c")
      redis.smove("key1", "key2", "b").should eq(1)
      redis.smembers("key1").should eq(["a"])
      sort(redis.smembers("key2")).should eq(["b", "c"])
    end

    it "#srandmember" do
      redis.del("key1", "key2", "destination")
      redis.sadd("key1", "a")
      redis.srandmember("key1", 1).should eq(["a"])
    end

    describe "#sscan" do
      it "no options" do
        redis.del("myset")
        redis.sadd("myset", "a", "b")
        new_cursor, keys = redis.sscan("myset", 0)
        new_cursor.should eq("0")
        sort(keys).should eq(["a", "b"])
      end

      it "with match" do
        redis.del("myset")
        redis.sadd("myset", "foo", "bar", "foo2", "foo3")
        new_cursor, keys = redis.sscan("myset", 0, "foo*", 2)
        new_cursor = new_cursor.as(String)
        keys.is_a?(Array).should be_true
        array(keys).size.should be > 0
      end

      it "with match and count" do
        redis.del("myset")
        redis.sadd("myset", "foo", "bar", "baz")
        new_cursor, keys = redis.sscan("myset", 0, "*a*", 1)
        new_cursor = new_cursor.as(String)
        new_cursor.to_i.should be > 0
        keys.is_a?(Array).should be_true
        # TODO SW: This assertion fails randomly
        # array(keys).size.should be > 0
      end

      it "with match and count at once" do
        redis.del("myset")
        redis.sadd("myset", "foo", "bar", "baz")
        new_cursor, keys = redis.sscan("myset", 0, "*a*", 10)
        new_cursor.should eq("0")
        keys.is_a?(Array).should be_true
        array(keys).sort.should eq(["bar", "baz"])
      end
    end
  end

  describe "hashes" do
    redis = Redis.new

    it "#hset / #hget" do
      redis.del("myhash")
      redis.hset("myhash", "a", "434")
      redis.hget("myhash", "a").should eq("434")
    end

    it "#hgetall" do
      redis.del("myhash")
      redis.hset("myhash", "a", "123")
      redis.hset("myhash", "b", "456")
      redis.hgetall("myhash").should eq(["a", "123", "b", "456"])
    end

    it "#hdel" do
      redis.del("myhash")
      redis.hset("myhash", "field1", "foo")
      redis.hdel("myhash", "field1").should eq(1)
      redis.hget("myhash", "field1").should eq(nil)
    end

    it "#hexists" do
      redis.del("myhash")
      redis.hset("myhash", "field1", "foo")
      redis.hexists("myhash", "field1").should eq(1)
      redis.hexists("myhash", "field2").should eq(0)
    end

    it "#hincrby" do
      redis.del("myhash")
      redis.hset("myhash", "field1", "1")
      redis.hincrby("myhash", "field1", "3").should eq(4)
    end

    it "#hincrbyfloat" do
      redis.del("myhash")
      redis.hset("myhash", "field1", "10.50")
      redis.hincrbyfloat("myhash", "field1", "0.1").should eq("10.6")
    end

    it "#hkeys" do
      redis.del("myhash")
      redis.hset("myhash", "field1", "1")
      redis.hset("myhash", "field2", "2")
      redis.hkeys("myhash").should eq(["field1", "field2"])
    end

    it "#hlen" do
      redis.del("myhash")
      redis.hset("myhash", "field1", "1")
      redis.hset("myhash", "field2", "2")
      redis.hlen("myhash").should eq(2)
    end

    it "#hmget" do
      redis.del("myhash")
      redis.hset("myhash", "a", "123")
      redis.hset("myhash", "b", "456")
      redis.hmget("myhash", "a", "b").should eq(["123", "456"])
    end

    it "#hmset" do
      redis.del("myhash")
      redis.hmset("myhash", {"field1": "a", "field2": 2})
      redis.hget("myhash", "field1").should eq("a")
      redis.hget("myhash", "field2").should eq("2")
    end

    describe "#hscan" do
      it "no options" do
        redis.del("myhash")
        redis.hmset("myhash", {"field1": "a", "field2": "b"})
        new_cursor, keys = redis.hscan("myhash", 0)
        new_cursor.should eq("0")
        keys.should eq(["field1", "a", "field2", "b"])
      end

      it "with match" do
        redis.del("myhash")
        redis.hmset("myhash", {"foo": "a", "bar": "b"})
        new_cursor, keys = redis.hscan("myhash", 0, "f*")
        new_cursor.should eq("0")
        keys.is_a?(Array).should be_true
        # {foo:a} is matched, and Redis returns the key and val as a single list
        array(keys).should eq(["foo", "a"])
      end

      # pending: hscan doesn't handle COUNT strictly
      # it "#hscan with match and count" do
      # end

      it "with match and count at once" do
        redis.del("myhash")
        redis.hmset("myhash", {"foo": "a", "bar": "b", "baz": "c"})
        new_cursor, keys = redis.hscan("myhash", 0, "*a*", 1024)
        new_cursor.should eq("0")
        keys.is_a?(Array).should be_true
        # extract odd elements for keys because hscan returns (key, val) as a single list
        keys = array(keys).in_groups_of(2).map(&.first.not_nil!)
        keys.sort.should eq(["bar", "baz"])
      end
    end

    it "#hsetnx" do
      redis.del("myhash")
      redis.hsetnx("myhash", "foo", "setnxed").should eq(1)
      redis.hget("myhash", "foo").should eq("setnxed")
      redis.hsetnx("myhash", "foo", "setnxed2").should eq(0)
      redis.hget("myhash", "foo").should eq("setnxed")
    end

    it "#hvals" do
      redis.del("myhash")
      redis.hset("myhash", "a", "123")
      redis.hset("myhash", "b", "456")
      redis.hvals("myhash").should eq(["123", "456"])
    end
  end

  describe "sorted sets" do
    redis = Redis.new

    it "#zadd / zrange" do
      redis.del("myzset")
      redis.zadd("myzset", 1, "one").should eq(1)
      redis.zadd("myzset", [1, "uno"]).should eq(1)
      redis.zadd("myzset", 2, "two", 3, "three").should eq(2)
      redis.zrange("myzset", 0, -1, with_scores: true).should eq(["one", "1", "uno", "1", "two", "2", "three", "3"])
    end

    it "#zrangebylex" do
      redis.del("myzset")
      redis.zadd("myzset", 0, "a", 0, "b", 0, "c", 0, "d", 0, "e", 0, "f", 0, "g")
      redis.zrangebylex("myzset", "-", "[c").should eq(["a", "b", "c"])
      redis.zrangebylex("myzset", "-", "(c").should eq(["a", "b"])
      redis.zrangebylex("myzset", "[aaa", "(g").should eq(["b", "c", "d", "e", "f"])
      redis.zrangebylex("myzset", "[aaa", "(g", limit: [0, 4]).should eq(["b", "c", "d", "e"])
    end

    it "#zrangebyscore" do
      redis.del("myzset")
      redis.zadd("myzset", 1, "one", 2, "two", 3, "three")
      redis.zrangebyscore("myzset", "-inf", "+inf").should eq(["one", "two", "three"])
      redis.zrangebyscore("myzset", "-inf", "+inf", limit: [0, 2]).should eq(["one", "two"])
    end

    it "#zrevrange" do
      redis.del("myzset")
      redis.zadd("myzset", 1, "one", 2, "two", 3, "three")
      redis.zrevrange("myzset", 0, -1).should eq(["three", "two", "one"])
      redis.zrevrange("myzset", 2, 3).should eq(["one"])
      redis.zrevrange("myzset", -2, -1).should eq(["two", "one"])
    end

    it "#zrevrangebylex" do
      redis.del("myzset")
      redis.zadd("myzset", 0, "a", 0, "b", 0, "c", 0, "d", 0, "e", 0, "f", 0, "g")
      redis.zrevrangebylex("myzset", "[c", "-").should eq(["c", "b", "a"])
      redis.zrevrangebylex("myzset", "(c", "-").should eq(["b", "a"])
      redis.zrevrangebylex("myzset", "(g", "[aaa").should eq(["f", "e", "d", "c", "b"])
      redis.zrevrangebylex("myzset", "+", "-", limit: [1, 1]).should eq(["f"])
    end

    it "#zrevrangebyscore" do
      redis.del("myzset")
      redis.zadd("myzset", 1, "one", 2, "two", 3, "three")
      redis.zrevrangebyscore("myzset", "+inf", "-inf").should eq(["three", "two", "one"])
      redis.zrevrangebyscore("myzset", "+inf", "-inf", limit: [0, 2]).should eq(["three", "two"])
    end

    it "#zscore" do
      redis.del("myzset")
      redis.zadd("myzset", 2, "two")
      redis.zscore("myzset", "two").should eq("2")
    end

    it "#zcard" do
      redis.del("myzset")
      redis.zadd("myzset", 2, "two", 3, "three")
      redis.zcard("myzset").should eq(2)
    end

    it "#zcount" do
      redis.del("myzset")
      redis.zadd("myzset", 1, "one", 2, "two", 3, "three")
      redis.zcount("myzset", "-inf", "+inf").should eq(3)
      redis.zcount("myzset", "(1", "3").should eq(2)
    end

    it "#zlexcount" do
      redis.del("myzset")
      redis.zadd("myzset", 0, "a", 0, "b", 0, "c", 0, "d", 0, "e", 0, "f", 0, "g")
      redis.zlexcount("myzset", "-", "+").should eq(7)
      redis.zlexcount("myzset", "[b", "[f").should eq(5)
    end

    it "#zrank" do
      redis.del("myzset")
      redis.zadd("myzset", 1, "one", 2, "two", 3, "three")
      redis.zrank("myzset", "one").should eq(0)
      redis.zrank("myzset", "three").should eq(2)
      redis.zrank("myzset", "four").should eq(nil)
    end

    describe "zscan" do
      it "no options" do
        redis.del("myset")
        redis.zadd("myzset", 1, "one", 2, "two", 3, "three")
        new_cursor, keys = redis.zscan("myzset", 0)
        new_cursor.should eq("0")
        keys.should eq(["one", "1", "two", "2", "three", "3"])
      end

      it "with match" do
        redis.del("myzset")
        redis.zadd("myzset", 1, "one", 2, "two", 3, "three")
        new_cursor, keys = redis.zscan("myzset", 0, "t*")
        new_cursor.should eq("0")
        keys.is_a?(Array).should be_true
        # extract odd elements for keys because zscan returns (key, val) as a single list
        keys = array(keys).in_groups_of(2).map(&.first.not_nil!)
        keys.should eq(["two", "three"])
      end

      # pending: zscan doesn't handle COUNT strictly
      # it "#zscan with match and count" do
      # end

      it "with match and count at once" do
        redis.del("myzset")
        redis.zadd("myzset", 1, "one", 2, "two", 3, "three")
        new_cursor, keys = redis.zscan("myzset", 0, "t*", 1024)
        new_cursor.should eq("0")
        keys.is_a?(Array).should be_true
        # extract odd elements for keys because zscan returns (key, val) as a single list
        keys = array(keys).in_groups_of(2).map(&.first.not_nil!)
        keys.should eq(["two", "three"])
      end
    end

    it "#zrevrank" do
      redis.del("myzset")
      redis.zadd("myzset", 1, "one", 2, "two", 3, "three")
      redis.zrevrank("myzset", "one").should eq(2)
      redis.zrevrank("myzset", "three").should eq(0)
      redis.zrevrank("myzset", "four").should eq(nil)
    end

    it "#zincrby" do
      redis.del("myzset")
      redis.zadd("myzset", 1, "one")
      redis.zincrby("myzset", 2, "one").should eq("3")
      redis.zrange("myzset", 0, -1, with_scores: true).should eq(["one", "3"])
    end

    it "#zrem" do
      redis.del("myzset")
      redis.zadd("myzset", 1, "one", 2, "two", 3, "three")
      redis.zrem("myzset", "two").should eq(1)
      redis.zcard("myzset").should eq(2)
    end

    it "#zremrangebylex" do
      redis.del("myzset")
      redis.zadd("myzset", 0, "aaaa", 0, "b", 0, "c", 0, "d", 0, "e")
      redis.zadd("myzset", 0, "foo", 0, "zap", 0, "zip", 0, "ALPHA", 0, "alpha")
      redis.zremrangebylex("myzset", "[alpha", "[omega")
      redis.zrange("myzset", 0, -1).should eq(["ALPHA", "aaaa", "zap", "zip"])
    end

    it "#zremrangebyrank" do
      redis.del("myzset")
      redis.zadd("myzset", 1, "one", 2, "two", 3, "three")
      redis.zremrangebyrank("myzset", 0, 1).should eq(2)
      redis.zrange("myzset", 0, -1, with_scores: true).should eq(["three", "3"])
    end

    it "#zremrangebyscore" do
      redis.del("myzset")
      redis.zadd("myzset", 1, "one", 2, "two", 3, "three")
      redis.zremrangebyscore("myzset", "-inf", "(2").should eq(1)
      redis.zrange("myzset", 0, -1, with_scores: true).should eq(["two", "2", "three", "3"])
    end

    it "#zinterstore" do
      redis.del("zset1", "zset2", "zset3")
      redis.zadd("zset1", 1, "one", 2, "two")
      redis.zadd("zset2", 1, "one", 2, "two", 3, "three")
      redis.zinterstore("zset3", ["zset1", "zset2"], weights: [2, 3]).should eq(2)
      redis.zrange("zset3", 0, -1, with_scores: true).should eq(["one", "5", "two", "10"])
    end

    it "#zunionstore" do
      redis.del("zset1", "zset2", "zset3")
      redis.zadd("zset1", 1, "one", 2, "two")
      redis.zadd("zset2", 1, "one", 2, "two", 3, "three")
      redis.zunionstore("zset3", ["zset1", "zset2"], weights: [2, 3]).should eq(3)
      redis.zrange("zset3", 0, -1, with_scores: true).should eq(["one", "5", "three", "9", "two", "10"])
    end
  end

  describe "#pipelined" do
    redis = Redis.new

    it "executes the commands in the block and returns the results" do
      futures = [] of Redis::Future
      results = redis.pipelined do |pipeline|
        pipeline.set("foo", "new value")
        futures << pipeline.get("foo")
      end
      results[1].should eq("new value")
      futures[0].value.should eq("new value")
    end

    it "raises an exception if we call methods on the Redis object" do
      redis.pipelined do |pipeline|
        expect_raises Redis::Error do
          redis.set("foo", "bar")
        end
      end
    end
  end

  describe "hyperloglog" do
    redis = Redis.new

    it "#pfadd / #pfcount" do
      redis.del("hll")
      redis.pfadd("hll", "a", "b", "c", "d", "e", "f", "g").should eq(1)
      redis.pfcount("hll").should eq(7)
    end

    it "#pfmerge" do
      redis.del("hll1", "hll2", "hll3")
      redis.pfadd("hll1", "foo", "bar", "zap", "a")
      redis.pfadd("hll2", "a", "b", "c", "foo")
      redis.pfmerge("hll3", "hll1", "hll2").should eq("OK")
      redis.pfcount("hll3").should eq(6)
    end
  end

  describe "#info" do
    it "returns server data" do
      redis = Redis.new
      x = redis.info
      x.size.should be >= 70

      x = redis.info("cpu")
      x.size.should eq(4)

      redis.info["redis_version"].should_not be_nil
    end
  end

  describe "#multi" do
    redis = Redis.new

    it "executes the commands in the block and returns the results" do
      futures = [] of Redis::Future
      results = redis.multi do |multi|
        multi.set("foo", "new value")
        futures << multi.get("foo")
      end
      results[1].should eq("new value")
      # future.not_nil!
      futures[0].value.should eq("new value")
    end

    it "does not execute the commands in the block upon #discard" do
      redis.set("foo", "initial value")
      results = redis.multi do |multi|
        multi.set("foo", "new value")
        multi.discard
      end
      redis.get("foo").should eq("initial value")
      results.should eq([] of Redis::RedisValue)
    end

    it "performs optimistic locking with #watch" do
      redis.set("foo", "1")
      current_value = redis.get("foo").not_nil!
      redis.watch("foo")
      results = redis.multi do |multi|
        other_redis = Redis.new
        other_redis.set("foo", "value set by other client")
        multi.set("foo", current_value + "2")
      end
      redis.get("foo").should eq("value set by other client")
    end

    it "#watch" do
      redis.set("foo", "1")
      redis.watch("foo")
      redis.unwatch
    end

    it "raises an exception if we call methods on the Redis object" do
      redis.multi do |multi|
        expect_raises Redis::Error do
          redis.set("foo", "bar")
        end
      end
    end
  end

  describe "LUA scripting" do
    redis = Redis.new

    describe "#eval" do
      it "executes the LUA script" do
        keys = ["key1", "key2"] of Redis::RedisValue
        args = ["first", "second"] of Redis::RedisValue
        result = redis.eval("return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}", keys, args)
        result.should eq(["key1", "key2", "first", "second"])
      end
    end

    describe "#script_load / #eval_sha" do
      it "registers a LUA script and calls it" do
        sha1 = redis.script_load("return {KEYS[1],ARGV[1]}")
        keys = ["key1", "key2"] of Redis::RedisValue
        args = ["first", "second"] of Redis::RedisValue
        result = redis.evalsha(sha1, keys, args)
        result.should eq(["key1", "first"])
      end
    end

    describe "#script_kill" do
      it "kills the currently running LUA script" do
        begin
          redis.script_kill
        rescue Redis::Error
        end
      end
    end

    describe "#script_exists" do
      it "checks if the given LUA scripts exist" do
        sha1 = redis.script_load("return 10")
        result = redis.script_exists([sha1, "fffffffffffffff"])
        result.should eq([1, 0])
      end
    end

    describe "#script_flush" do
      it "flushes the LUA script cache" do
        sha1 = redis.script_load("return 10")
        redis.script_flush
        redis.script_exists([sha1]).should eq([0])
      end
    end
  end

  describe "#type" do
    redis = Redis.new

    it "returns a value's type as a string" do
      redis.set("foo", 3)
      redis.type("foo").should eq("string")
    end
  end

  describe "#flush" do
    redis = Redis.new

    it "flushdb" do
      redis.flushdb.should eq("OK")
    end

    it "flushall" do
      redis.flushall.should eq("OK")
    end
  end

  describe "expiry" do
    redis = Redis.new

    it "#expire" do
      redis.set("temp", "3")
      redis.expire("temp", 2).should eq(1)
    end

    it "#expireat" do
      redis.set("temp", "3")
      redis.expireat("temp", 1555555555005).should eq(1)
      redis.ttl("temp").should be > 3000
    end

    it "#ttl" do
      redis.set("temp", "9")
      redis.ttl("temp").should eq(-1)
      redis.expire("temp", 3)
      redis.ttl("temp").should eq(3)
    end

    it "#pexpire" do
      redis.set("temp", "3")
      redis.pexpire("temp", 1000).should eq(1)
    end

    it "#pexpireat" do
      redis.set("temp", "3")
      redis.pexpireat("temp", 1555555555005).should eq(1)
      redis.pttl("temp").should be > 2990
    end

    it "#pttl" do
      redis.set("temp", "9")
      redis.pttl("temp").should eq(-1)
      redis.pexpire("temp", 3000)
      redis.pttl("temp").should be > 2990
    end

    it "#persist" do
      redis.set("temp", "9")
      redis.expire("temp", 3)
      redis.ttl("temp").should eq(3)
      redis.persist("temp")
      redis.ttl("temp").should eq(-1)
    end
  end

  describe "publish / subscribe" do
    redis = Redis.new

    it "#publish" do
      redis.publish("mychannel", "my message")
    end

    it "#subscribe / #unsubscribe" do
      callbacks_received = [] of String
      redis.subscribe("mychannel") do |on|
        on.subscribe do |channel, subscriptions|
          channel.should eq("mychannel")
          subscriptions.should eq(1)
          callbacks_received << "subscribe"

          # Send a message to ourselves so that we can test the other callbacks.
          # We need a second connection to do so.
          Redis.open do |other_redis|
            other_redis.publish("mychannel", "just talking to myself")
          end
        end

        on.message do |channel, message|
          channel.should eq("mychannel")
          message.should eq("just talking to myself")
          callbacks_received << "message"

          # Great, we are done.
          redis.unsubscribe("mychannel")
        end

        on.unsubscribe do |channel, subscriptions|
          channel.should eq("mychannel")
          subscriptions.should eq(0)
          callbacks_received << "unsubscribe"
        end
      end

      callbacks_received.should eq(["subscribe", "message", "unsubscribe"])
    end
  end

  describe "punsubscribe" do
    redis = Redis.new

    it "#psubscribe / #punsubscribe" do
      callbacks_received = [] of String

      redis.psubscribe("otherchan*") do |on|
        on.psubscribe do |channel_pattern, subscriptions|
          channel_pattern.should eq("otherchan*")
          subscriptions.should eq(1)
          callbacks_received << "psubscribe"

          # Send a message to ourselves so that we can test the other callbacks.
          # We need a second connection to do so.
          Redis.open do |other_redis|
            other_redis.publish("otherchannel", "hello subscriber")
          end
        end

        on.pmessage do |channel_pattern, channel, message|
          channel_pattern.should eq("otherchan*")
          channel.should eq("otherchannel")
          message.should eq("hello subscriber")
          callbacks_received << "pmessage"

          # Great, we are done.
          redis.punsubscribe("otherchan*")
        end

        on.punsubscribe do |channel_pattern, subscriptions|
          channel_pattern.should eq("otherchan*")
          subscriptions.should eq(0)
          callbacks_received << "punsubscribe"
        end
      end

      callbacks_received.should eq(["psubscribe", "pmessage", "punsubscribe"])
    end
  end

  describe "OBJECT commands" do
    redis = Redis.new

    it "#object_refcount" do
      redis.del("mylist")
      redis.rpush("mylist", "Hello", "World")
      redis.object_refcount("mylist").should eq(1)
    end

    it "#object_encoding" do
      redis.del("mylist")
      redis.rpush("mylist", "Hello", "World")
      redis.object_encoding("mylist").should eq("quicklist")
    end

    it "#object_idletime" do
      redis.del("mylist")
      redis.rpush("mylist", "Hello", "World")
      redis.object_idletime("mylist").should eq(0)
    end
  end

  describe "large values" do
    redis = Redis.new

    it "sends and receives a large value correctly" do
      redis.del("foo")
      large_value = "0123456789" * 100_000 # 1 MB
      redis.set("foo", large_value)
      redis.get("foo").should eq(large_value)
    end
  end
end
