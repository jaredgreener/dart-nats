import 'package:nats/nats.dart';

void main() async {
  var client = NatsClient("localhost", 4222);
  await client.connect(connectionOptions: ConnectionOptions()..protocol = 1);
  client.subscribe("sub-1", "foo").listen((msg) {
    print("Incoming payload");
  });
}
