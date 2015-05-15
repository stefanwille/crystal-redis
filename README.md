Redis Client for Crystal-Lang
================================

A Redis client for the Crystal programming language.


## Features

* Performance (> 260.000 commands per second using pipeline on a MacBook Air with a single client thread)
* Pipelining
* Transactions
* LUA Scripting
* All string commands
* All hash commands
* All list commands
* All set commands
* All hyperloglog commands
* All commands for bit operations
* All sorted set commands
* Publish/subscribe


## Installation

Add it to `Projectfile`

```crystal
deps do
  github "stefanwille/crystal-redis"
end
```

and then download the library into your project:

```bash
$ crystal deps
```


## Required Crystal Version

This library needs Crystal version >= 0.7.1.


## Usage

Require the package:

```crystal
  require "redis"
```

then

```crystal
  redis = Redis.new
```

Then you can call Redis commands on the `redis` object:

```crystal
  redis.set("foo", "bar")
  redis.get("foo")
```

## Documentation

To get started,

* see this [basic example](https://github.com/stefanwille/crystal-redis/blob/master/examples/basic.cr)
* look at more examples in the [examples directory](https://github.com/stefanwille/crystal-redis/blob/master/examples/)
* see the [API documentation](http://stefanwille.github.io/crystal-redis/doc/) -
start reading it at the class `Redis`.

More details are available at:

* [Redis commands documentation](http://redis.io/commands) - the original Redis documentation is necessary, as the API documentation above is just a quick reference
* [spec/redis.cr](https://github.com/stefanwille/crystal-redis/blob/master/spec/redis.cr) - offers more usage examples
* [Redis documentation page](http://redis.io/documentation) - general information about Redis and its concepts


## Performance

* Crystal: With this library I get > 260.000 commands per second using pipeline on a MacBook Air with a single client thread.

* C: The equivalent program written in C with Hiredis gets me 340.000 commands per second.

* Ruby: Ruby 2.2.1 with the [redis-rb](https://github.com/redis/redis-rb) handles 50.000 commands per second.


## Status

I have exercised every API method in the spec and built some example programs. There is no critical production use yet.

I took great care to make this library very usable with respect to to API, reliability and documentation.


## Questions, Bugs & Support

If you have questions or need help, please open a ticket in the [GitHub issue tracker](https://github.com/stefanwille/crystal-redis/issues). This way others can benefit from the discussion.
