import 'package:nats/nats.dart';

void main() async {
  var client = NatsClient("localhost", 4222);
  await client.connect(
      connectionOptions: ConnectionOptions()..protocol = 1,
      onClusterupdate: (serverInfo) {
        print("Got new update: ${serverInfo.serverUrls}");
      });

  client.publish("Hello world", "foo");
}
