Redis Client for Crystal-Lang
================================

A Redis client for the Crystal programming language.


## Features

- Performance (> 200.000 commands per second using pipeline on a MacBook Air with a single client thread)
- Pipelining
- Transactions
- LUA Scripting
- All string commands
- All hash commands
- All list commands
- All set commands
- All hyperloglog commands
- All commands for bit operations
- All sorted set commands
- Pub/sub


## Installation

Add it to `Projectfile`

```crystal
deps do
  github "stefanwille/crystal-redis"
end
```

and then download the library into your project:

```crystal
$ crystal deps
```


## Required Crystal Version


**Note: Needs a Crystal version > 0.6.1!**

## Usage

```crystal
require "redis"
```

then

```crystal
  redis = Redis.new
```
or

```crystal
  redis = Redis.new(host: "localhost", port: 6379)
```

Then you can call Redis commands on the `redis` object:

```crystal
  redis.set('foo', 'bar')
  redis.get('foo')
```

See spec/redis.cr for more details about all the commands.


## TODO

- Write examples for
  o transactions
  o pub/sub
  o one per datatype
- Cleanup the commit history
- Announce on mailing list
- Publish the URL to http://redis.io/clients
- Watch/Unwatch
- Documentation pointers

- Dump/Restore
- OBJECT
- MOVE
- Protocol spec
- Reconnect
- Unix domain sockets
- Sentinel
- Aesthetics:
  - hgetall returns a hash instead of a list
  - script_exists returns an array of booleans instead of ints
  - setnx returns a boolean instead of an int
  - msetnx returns a boolean instead of an int
  - incrbyfloat returns a float, not a string
  - hincrbyfloat returns a float, not a string
  - hscan returns a hash, not an array
  - zscan returns a hash, not an array
  - hsetnx returns a boolean instead of an int
  - sismember returns a boolean instead of an int
  - exists returns a boolean instead of an int
  - zadd returns a hash instead of an array
  - zrange returns a hash instead of an array
  - zscore returns a double instead of a string



## Hacking

To run the spec, you need a Redis server on `localhost` / port `6379` (which is the default port).

The server also needs to accept Unix domain connections at `/tmp/redis.sock`. This means that you need the following two lines in your `redis.conf`:

```
unixsocket /tmp/redis.sock
unixsocketperm 755
```


## Contributing

1. Fork it ( https://github.com/stefanwille/crystal-redis/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

