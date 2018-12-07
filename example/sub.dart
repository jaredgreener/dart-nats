import 'package:nats/nats.dart';
import 'package:logging/logging.dart';

void main() async {
  var client = NatsClient("localhost", 4222, logLevel: Level.INFO);

  await client.connect(
      connectionOptions: ConnectionOptions()..protocol = 1,
      onClusterupdate: (serverInfo) {
      });

  client.subscribe("sub-1", "foo").listen((msg) {
    print("Got message: ${msg.payload}");
  });
}
