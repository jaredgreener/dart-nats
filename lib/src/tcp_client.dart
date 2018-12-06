import 'dart:io';
import 'package:rxdart/rxdart.dart';
import 'constants.dart';

/// Class to handle NATS-text interaction
class TcpClient {
  final String host;
  final int port;

  TcpClient({this.host, this.port});

  /// Returns an observable of either a [Socket] or an [Exception]
  Future<Socket> connect() => Socket.connect(host, port);
}
