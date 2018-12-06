import 'package:nats/nats.dart';
import 'package:test/test.dart';
import "dart:io";

void main() async {
  NatsClient client = NatsClient("localhost", 4222);
  await client.connect();
  assert(client.checkSocketReady());
  client.publish("Hello", "foo");
}
