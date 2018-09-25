# Redis Client for Crystal

[![Build Status](https://img.shields.io/travis/stefanwille/crystal-redis/master.svg?style=flat)](https://travis-ci.org/stefanwille/crystal-redis) [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md#pull-requests)

A Redis client for the Crystal programming language.

## Features

- Performance (> 680,000 commands per second using pipeline on a MacBook Air with a single client thread)
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
- Publish/subscribe

## Installation

Add it to your `shard.yml`:

```crystal
dependencies:
  redis:
    github: stefanwille/crystal-redis
    version: ~> 2.1.1
```

and then install the library into your project:

```bash
$ shards install
```

### Installation on MacOS X

On MacOS X you may get this error:

```
ld: library not found for -lssl (this usually means you need to install the development package for libssl)
clang: error: linker command failed with exit code 1 (use -v to see invocation)
...
```

Or this warning:

```
Package libssl was not found in the pkg-config search path.
Perhaps you should add the directory containing `libssl.pc'
to the PKG_CONFIG_PATH environment variable
No package 'libssl' found
Package libcrypto was not found in the pkg-config search path.
Perhaps you should add the directory containing `libcrypto.pc'
to the PKG_CONFIG_PATH environment variable
No package 'libcrypto' found
```

The problem is that Crystal can't find openssl, because it is not installed by default on MacOS X.

The fix:

1.  Install openssl via [Homebrew](https://brew.sh/):

```bash
$ brew install openssl
```

2.  Set the environment variable `PKG_CONFIG_PATH`:

```bash
$ export PKG_CONFIG_PATH=/usr/local/opt/openssl/lib/pkgconfig
```

Note: Please write me if you know a better way!

## Required Crystal Version

This library needs Crystal version >= 0.25.0

I haven't tested older Crystal versions.

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

#### Connection Pooling

Since version 2.0.0, a connection pool is built in. It is used implicitly through `Redis::PooledClient`:

```Crystal
redis = Redis::PooledClient.new
10.times do |i|
  spawn do
    redis.set("foo#{i}", "bar")
    redis.get("foo#{i}") # => "bar"
  end
end
```

This `redis` instance can be shared across fibers, and accepts the same Redis commands as the `Redis` class.
It automatically allocates and frees connections from/to the pool, per command.

## Examples

To get started, see the examples:

- There is a separate git repository [crystal-redis-examples](https://github.com/stefanwille/crystal-redis-examples) with examples.
- start with this [basic example](https://github.com/stefanwille/crystal-redis-examples/blob/master/src/basic.cr)
- look at [the other examples](https://github.com/stefanwille/crystal-redis-examples/blob/master/src/)
- the [spec](https://github.com/stefanwille/crystal-redis/blob/master/spec/redis_spec.cr) contains even more usage examples

## Documentation

- [API documentation](http://stefanwille.github.io/crystal-redis) -
  start reading it at the class `Redis`.
- [Redis commands documentation](http://redis.io/commands) - the original Redis documentation is necessary, as the API documentation above is just a quick reference
- [Redis documentation page](http://redis.io/documentation) - general information about Redis and its concepts

## Performance

I have benchmarked Crystal-Redis against several other client libraries in various programming languages in this [blog article](http://www.stefanwille.com/2015/05/redis-clients-crystal-vs-ruby-vs-c-vs-go/).

Here are some results:

- Crystal: With this library I get > 680,000 commands per second using pipeline on a MacBook Air with a single client thread.

- C: The equivalent program written in C with Hiredis gets me 340,000 commands per second.

- Ruby: Ruby 2.2.1 with the [redis-rb](https://github.com/redis/redis-rb) and Hiredis driver handles 150,000 commands per second.

[Read more results](http://www.stefanwille.com/2015/05/redis-clients-crystal-vs-ruby-vs-c-vs-go/) for Go, Java, Node.js.

## Status

I have exercised every API method in the spec and built some example programs. There is no production use yet.

I took great care to make this library very usable with respect to API, reliability and documentation.

## Development

This project requires a locally running redis server running on port 6379 and with a unix socket located at /tmp/redis.sock. Then you can run the specs via

`$ crystal spec`

[See more information](https://github.com/stefanwille/crystal-redis/blob/master/CONTRIBUTING.md).

### WARNING

Running the spec will delete database number 0!

## Questions, Bugs & Support

If you have questions or need help, please open a ticket in the [GitHub issue tracker](https://github.com/stefanwille/crystal-redis/issues). This way others can benefit from the discussion.
