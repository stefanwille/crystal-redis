class Redis
  module Commands
    def echo(string)
      string_command(["ECHO", string.to_s])
    end
  end
end