import 'dart:io';
import 'package:rxdart/rxdart.dart';

/// Class to handle NATS-text interaction
class TcpClient {
  final String host;
  final int port;

  TcpClient({this.host, this.port});

  /// Returns an observable of either a [Socket] or an [Exception]
  Observable<Socket> connect() => Observable.fromFuture((Socket.connect(host, port)));  
}
