# nats-dart
NATS client to usage in Dart CLI, Web and Flutter projects

### Setting up a client
Setting up a client and firing up a connection
```dart
var client = NatsClient("localhost", 4222);
await client.connect();
```
**Note**: Never use a client without waiting for the connection to establish

### Publishing a message
Publishing a message can be done with or without a `reply-to` topic
```dart
// No reply-to topic set
client.publish("Hello world", "foo");

// If server replies to this request, send it to `bar`
client.publish("Hello world", "foo", "bar");
```

### Subscribing to messages
To subscribe to a topic, specify the topic and optionally, a queue group
```dart
var messageStream = client.subscribe("foo");

// If more than one subscriber uses the same queue group,
// only one will receive the message
var messageStream = client.subscribe("foo", "group-1");

messageStream.listen((message) {
    // Do something awesome
});
```

## Roadmap
- Support clustering
- Support multiple topic subscriptions

## Contributions
- No rules. Fork, change, PR.

## FAQs
### Can I use this in dart projects?
Not yet. The API is not yet finalised NATS protocol is not fully supported.

### When will this be ready?
Soon I guess. Feel free to pitch in and it'll be ready sooner.