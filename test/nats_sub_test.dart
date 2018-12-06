import 'package:nats/nats.dart';

void main() async {
  var client = NatsClient("localhost", 4222);
  await client.connect();

  client.subscribe("sub-id", "foo").listen((msg) {
    print("Received at listener: ${msg.payload}");
  });
}
