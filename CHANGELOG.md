## 2.8.0
* **breaking-change**: `zadd` return Int64 | String (instead of Int64) (#112)
* **breaking-change**: `hgetall` now returns Hash(String, String) instead of Array(String) (#4, #77)
* **breaking-change**: `hscan` now returns Hash(String, String) instead of Array(String) as second result
* Fix `del` to receive Array(RedisValue) (#100, #101, #105)
* Add `hset` method with Hash argument (#113, thanks @tachyons)
* Fix `brpoplpush` to work with namespaces
* Add `geosearch` method (#115, thanks @yrgoldteeth)
* Unsubscribe now reset connection, and can be used as usual (#106, #108)
* Add options for `zadd`: nx, xx, ch, incr (#112, thanks @noellabo)
* Fixed `ping` command in subscribe (#28)

## Previous versions:
* Please see https://github.com/stefanwille/crystal-redis/releases

