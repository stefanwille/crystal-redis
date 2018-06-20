require "./spec_helper"

describe Redis::PooledClient do
  it "handles commands like a Redis instance" do
    client = Redis::PooledClient.new(pool_size: 5)
    client.set("bla3", "a")
    client.get("bla3").should eq "a"
  end

  describe "pool_timeout option" do
    it "raises Redis::PooledClientError when no free connection is available after the given time" do
      client = Redis::PooledClient.new(pool_size: 2, pool_timeout: 0.01)
      client.pool.checkout
      client.pool.checkout

      expect_raises(Redis::PoolTimeoutError, "No free connection (used 2 of 2) after timeout of 0.01s") do
        client.get("bla")
      end
    end
  end

  it "passes other connection options to Redis instance" do
    redis1 = Redis::PooledClient.new(host: "localhost", port: 6379, database: 1)
    redis2 = Redis::PooledClient.new(host: "localhost", port: 6379, database: 2)

    redis1.del("test_database")
    redis2.del("test_database")

    redis1.set("test_database", "1")
    redis2.set("test_database", "2")

    redis1.get("test_database").should eq "1"
    redis2.get("test_database").should eq "2"
  end

  it "works with #pipelined" do
    client = Redis::PooledClient.new(pool_size: 5)
    client.pipelined do |pipeline|
      pipeline.del("foo")
      pipeline.del("foo1")
      pipeline.del("foo2")
      pipeline.del("foo3")
      pipeline.set("foo1", "first")
      pipeline.set("foo2", "second")
      pipeline.set("foo3", "third")
    end

    client.get("foo2").should eq "second"
  end

  it "works with transaction" do
    client = Redis::PooledClient.new(pool_size: 5)
    client.multi do |multi|
      multi.del("foo")
      multi.del("foo1")
      multi.del("foo2")
      multi.del("foo3")
      multi.set("foo1", "first")
      multi.set("foo2", "second")
      multi.set("foo3", "third")
    end

    client.get("foo2").should eq "second"
  end

  it "works with transaction with futures" do
    client = Redis::PooledClient.new(pool_size: 5)
    future_1 = Redis::Future.new
    future_2 = Redis::Future.new
    client.multi do |multi|
      multi.set("foo1", "A")
      multi.set("foo2", "B")
      future_1 = multi.get("foo1")
      future_2 = multi.get("foo2")
    end

    future_1.value.should eq "A"
    future_2.value.should eq "B"
  end

  it "supports concurrent use of a single instance" do
    client = Redis::PooledClient.new(pool_size: 200)
    client.del("test-queue")
    res = [] of String
    checks = 0

    n1 = 20
    n2 = 50

    n1.times do |i|
      spawn do
        n2.times do |j|
          client.set("key-#{i}-#{j}", "#{i}-#{j}")
          client.rpush("test-queue", "#{i}-#{j}")
          sleep 0.0001
        end
      end
    end

    ch = Channel(Bool).new

    n1.times do
      spawn do
        loop do
          if v = client.lpop("test-queue")
            res << v
            if client.get("key-#{v}") == v
              checks += 1
              client.del("key-#{v}")
            end
          else
            sleep 0.0001
          end

          break if res.size >= n1 * n2
        end
        ch.send(true)
      end
    end

    n1.times { ch.receive }

    res.size.should eq n1 * n2
    res.uniq.size.should eq n1 * n2

    checks.should eq n1 * n2

    uniqs = [] of Int64

    res.each do |v|
      a, b = v.split('-')
      uniqs << (a.to_i64 * n2 + b.to_i64).to_i64
    end

    uniqs.sum.should eq ((n1 * n2 - 1).to_i64 * n1.to_i64 * n2.to_i64).to_i64 / 2
  end
end
