import "package:nats/nats.dart";

void main() async { 
 var client1 = NatsClient("localhost", 4222);
    var client2 = NatsClient("localhost", 4222);
    await client1.connect();
    await client2.connect();

    client1.subscribe("sub-1", "foo").listen((msg) {
      print(msg);
    });

    client2.publish("Hello world", "foo");

}
