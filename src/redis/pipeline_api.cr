# API for sending commands in pipelined mode.
#
# Used in Redis#pipelined.
#
class Redis::PipelineApi
  def initialize(@strategy)
  end

  include Redis::Commands
  include Redis::FutureOrientedCommandExecution

  def command(request : Request)
    @strategy.command(request) as Redis::Future
  end
end
