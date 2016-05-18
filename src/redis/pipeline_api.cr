require "./command_execution/future_oriented"

# API for sending commands in pipelined mode.
#
# Used in Redis#pipelined.
#
# Example:
#
# ```
# redis.pipelined do |pipeline|
#   pipeline.set("foo1", "first")
#   pipeline.set("foo2", "second")
# end
# ```
#
# In this example, the `pipeline` object passed to the block is a PipelineApi
# object.
class Redis::PipelineApi
  @strategy : Redis::Strategy::Pipeline

  def initialize(@strategy)
  end

  include Redis::Commands
  # :nodoc:
  include Redis::CommandExecution::FutureOriented

  # :nodoc:
  def command(request : Request) : Redis::Future
    @strategy.command(request)
  end
end
