## v1.5.1

* Correctly tag the release.

## v1.5.0

* Fix parameter default syntax for Crystal 0.14 (thanks to Don Park). This makes Crystal 0.14 required.


## v1.4.0

* INCOMPATIBLE API CHANGE: Fix the parameter order of SETEX and PSETEX. According to the official Redis documentation at http://redis.io/commands the setex command is SETEX key seconds value. psetex should be identical to setex except with a ttl time in milliseconds. (thanks to Brian Mason)


## v1.3.1

* When connecting to a password protected Redis server, the password can now be passed as constructor parameter. For example: Redis.new(host: "localhost", port: 6379, password: "foobared"). Fixes #10


## v1.3.0

* Change the Shard name from "crystal-redis" to "redis" (Thanks to Ary Borenszweig)


## v1.2.1

* Fix issue #8 where large values were not received correctly (thanks to Edward Dorrington + Ary Borenszweig)


## v1.2.0

* Support and require Crystal 0.9.0


## v1.1.0

* Support and require Crystal 0.8.0  (thanks to Xanders)


## v1.0.1

* Support Crystal 0.7.5  (thanks to Joris Vanhecke)
* Improve performance (thanks to Ary Borenszweig)


## v1.0.0

* Initial release

