require "spec"
require "../src/redis"

# A poor man's sort for an array of redis values.
#
# I don't know how to do this better within Crystal's type system.
def sort(a)
  unless a.is_a? Array(Redis::RedisValue)
    raise "Cannot sort this: #{a.class}"
  end

  convert_to_string_array(a).sort
end

def convert_to_string_array(a)
  a.map { |item| item.to_s }
end

# Same as `sort` except sorting feature
def array(a) : Array(String)
  (a.as(Array(Redis::RedisValue))).map(&.to_s)
rescue
  raise "Cannot convert to Array(Redis::RedisValue): #{a.class}"
end

TEST_UNIXSOCKET = ENV["CI_UNIXSOCKET"]? || "/tmp/redis.sock"
PASSWORD_PORT   = 6380
