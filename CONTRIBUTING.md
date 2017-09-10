## Preparing a Pull Request

1. Fork it ( https://github.com/stefanwille/crystal-redis/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Run the spec
4. Run "rake" to make sure that the examples still work
5. Commit your changes (git commit -am 'Add some feature')
6. Push to the branch (git push origin my-new-feature)
7. Create a new Pull Request



## Running the Spec

To run the spec, you need a Redis 4 server on `localhost` / port `6379` (which is the default port).

The server also needs to accept Unix domain connections at `/tmp/redis.sock`. This means that you need the following two lines in your `redis.conf`:

```
unixsocket /tmp/redis.sock
unixsocketperm 755
```

Run the spec as usual via

```bash
$ crystal spec
```
