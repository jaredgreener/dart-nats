import 'package:nats/nats.dart';

void main() async {
  var client = NatsClient("localhost", 4222);
  await client.connect();

  client.publish("Hello world", "foo");
}
