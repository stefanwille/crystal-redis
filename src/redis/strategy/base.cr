abstract class Redis::Strategy::Base
  def begin
    raise "Redis: begin: We are not in a pipeline or transaction"
  end

  def discard
    raise "Redis: discard: We are not in a pipeline or transaction"
  end

  def commit
    raise "Redis: commit: We are not in a pipeline or transaction"
  end
end

