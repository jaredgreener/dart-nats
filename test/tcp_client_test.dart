import 'package:nats/nats.dart';
import 'package:test/test.dart';

void main() {
  final client = TcpClient(host: "localhost", port: 4222);
  client.connect().listen((socket) {
    
  }, onError: (err) {
    print("Got error");
  }, onDone: () {
    print("Done");
  });
}
