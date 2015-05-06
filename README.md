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
- Publish/subscribe


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

This library needs Crystal version >= 0.7.1.


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
  redis.set("foo", "bar")
  redis.get("foo")
```


## Documentation

To get started, see https://github.com/stefanwille/crystal-redis/blob/master/examples/basic.cr.

More examples are in https://github.com/stefanwille/crystal-redis/blob/master/examples/

More details about the available commands are in http://redis.io/commands and spec/redis.cr.

General information about Redis is at http://redis.io/documentation


