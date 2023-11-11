import 'package:flutter_nats/common/connection_options.dart';
import 'package:flutter_nats/models/nats_message.dart';
import 'package:meta/meta.dart';

@immutable
abstract class ClientEvent {
  const ClientEvent();
}

class Initialize extends ClientEvent{}
class Connect extends ClientEvent{
  final Function onConnect;
  const Connect(void this.onConnect());
}
class SetServerInfo extends ClientEvent{
  final String info;
  const SetServerInfo(this.info);
}
class ReConnect extends ClientEvent{}
class ReConnectToNextInCluster extends ClientEvent{}
class Subscribe extends ClientEvent{
  final String subject;
  final void Function(NatsMessage) onMessage;
  const Subscribe(this.subject, this.onMessage);
}
class UnSubscribe extends ClientEvent{
  final String subject;
  const UnSubscribe(this.subject);
}
class Close extends ClientEvent{}
class ReSubscribe extends ClientEvent{}
class Publish extends ClientEvent{
  final String subject;
  final String message;
  final String? replyTo;
  const Publish(this.subject, this.message, {this.replyTo});
}
class DataReceived extends ClientEvent{
  final dynamic data;
  const DataReceived(this.data);
}
class HandleError extends ClientEvent{}
class SendPing extends ClientEvent{}
class SendConnectionOptions extends ClientEvent{
  final ConnectionOptions options;
  SendConnectionOptions(this.options);
}

