class FutureClient
  include Redis::Commands

  def initialize(@strategy)
  end

  def string_command(request : Request)
    @strategy.command(request) as Redis::Future
  end
end
