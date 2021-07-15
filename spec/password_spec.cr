require "./spec_helper"

describe Redis do
  describe ".new with password" do
    it "connects with a password" do
      redis = Redis.new(host: "localhost", port: PASSWORD_PORT, password: "secret_password")
      redis.set("foo", "bar")
    end

    it "not connects with wrong password" do
      expect_raises(Redis::Error, /WRONGPASS/) do
        redis = Redis.new(host: "localhost", port: PASSWORD_PORT, password: "bla")
        redis.set("foo", "bar")
      end
    end

    it "not connects without password" do
      expect_raises(Redis::Error, /NOAUTH/) do
        redis = Redis.new(host: "localhost", port: PASSWORD_PORT)
        redis.set("foo", "bar")
      end
    end
  end
end
