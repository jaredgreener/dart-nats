import 'package:flutter_nats/nats.dart';

void main() async {

  var client = NatsClient("localhost", 4222, connectionOptions: ConnectionOptions()..protocol = 1, onConnect: (){

  });

}
