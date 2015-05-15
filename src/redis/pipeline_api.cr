require "./command_execution/future_oriented"

# API for sending commands in pipelined mode.
#
# Used in Redis#pipelined.
#
# Example:
#
# ```
# redis.pipelined do |pipeline|
#     pipeline.set("foo1", "first")
#     pipeline.set("foo2", "second")
# end
# ```
#
# In this example, the `pipeline` object passed to the block is a PipelineApi
# object.
class Redis::PipelineApi
  def initialize(@strategy)
  end

  include Redis::Commands
  include Redis::CommandExecution::FutureOriented

  def command(request : Request)
    @strategy.command(request) as Redis::Future
  end
end
