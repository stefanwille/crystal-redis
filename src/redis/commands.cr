class Redis
  module Commands
    def echo(string)
      string_command(["ECHO", string.to_s])
    end

    def set(key, value, ex = nil, px = nil, nx = nil, xx = nil)
      q = ["SET", key.to_s, value.to_s]
      q << "EX" << ex.to_s if ex
      q << "PX" << px.to_s if px
      q << "NX" << nx.to_s if nx
      q << "XX" << xx.to_s if xx
      string_or_nil_command(q)
    end

    def get(key)
      string_or_nil_command(["GET", key.to_s])
    end

    def discard
      @strategy.discard
    end
  end
end