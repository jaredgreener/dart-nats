import 'dart:async';

import 'package:flutter_nats/models/nats_message.dart';

class Subscription {
  final String _subject;
  final int _subscriptionID;
  final String? _queueGroup;
  StreamSubscription<NatsMessage>? listener;
  final void Function(NatsMessage) onMessage;

  Subscription(this._subject, this._subscriptionID, void this.onMessage(NatsMessage msg), {queueGroup}) : _queueGroup = queueGroup;

  int get subscriptionID => _subscriptionID;
  String get subject => _subject;

}
