# Example for Publish/Subscribe

First start one or more subscribers:

```bash
$ crystal run examples/publish-subscribe/subscribe.cr
```

Then start one or more publishers in separate terminal windows:

```bash
$ crystal run examples/publish-subscribe/publish.cr
```

Now when you type a message in the prompt of one of the publishers, it will
send it to all of the subscribers.

More information on Redis publish/subscribe is available here: http://redis.io/topics/pubsub