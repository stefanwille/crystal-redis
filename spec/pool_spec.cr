require "./spec_helper"

describe Redis::Pool do
  describe ".new" do
    it "connects to default host and port" do
      redis_pool = Redis::Pool.new(pool_size: 10)
    end

    it "connects to specific port and host / disconnects" do
      redis_pool = Redis::Pool.new(host: "localhost", port: 6379, pool_size: 10)
    end

    describe "#close" do
      it "closes all connections" do
        redis_pool = Redis::Pool.new
        redis_pool.close
      end
    end
  end

  describe "#checkout" do
    it "provides a Redis instance to the current coroutine until an explicit call to #checkin" do
      redis_pool = Redis::Pool.new
      redis = redis_pool.checkout
      redis.set("mike", "rules")
      redis.get("mike").should eq("rules")
      redis_pool.checkin
    end
  end

  describe "#connection" do
    it "executes the given block with a Redis instance from the pool" do
      redis_pool = Redis::Pool.new
      redis_pool.connection do |redis|
        redis.set("mike", "rules")
        redis.get("mike").should eq("rules")
      end
    end
  end
end
