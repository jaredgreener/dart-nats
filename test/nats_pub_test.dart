import 'package:nats/nats.dart';

void main() async {
  var client = NatsClient("localhost", 4222);
  await client.connect();

  for (int i = 0; i < 10; i++) {
    print("Sent $i");
    client.publish("Hello world", "foo");
  }
}
