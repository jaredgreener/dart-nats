import 'constants.dart';
import 'tcp_client.dart';
import 'server_info.dart';
import 'nats_message.dart';
import 'connection_options.dart';

import 'dart:io';
import "dart:convert";
import 'dart:async';

class NatsClient {
  Socket _socket;
  TcpClient _tcpClient;
  ServerInfo _serverInfo;

  StreamController<NatsMessage> _messagesController;

  NatsClient(String host, int port) {
    _serverInfo = ServerInfo();
    _messagesController = new StreamController.broadcast();
    _tcpClient = TcpClient(host: host, port: port);
  }

  /// Connects to the given NATS url
  ///
  /// ```dart
  /// var client = NatsClient("localhost", 4222);
  /// var options = ConnectionOptions()
  /// options
  ///  ..verbose = true
  ///  ..pedantic = false
  ///  ..tlsRequired = false
  /// await client.connect(connectionOptions: options);
  /// ```
  void connect({ConnectionOptions connectionOptions}) async {
    _socket = await _tcpClient.connect();
    _socket.transform(utf8.decoder).listen((data) {
      _serverPushString(data, connectionOptions: connectionOptions);
    });
  }

  void _serverPushString(String serverPushString,
      {ConnectionOptions connectionOptions}) {
    String infoPrefix = INFO;
    String messagePrefix = MSG;
    String pingPrefix = PING;

    if (serverPushString.startsWith(infoPrefix)) {
      _setServerInfo(serverPushString.replaceFirst(infoPrefix, ""),
          connectionOptions: connectionOptions);
    } else if (serverPushString.startsWith(messagePrefix)) {
      _convertToMessages(serverPushString)
          .forEach((msg) => _messagesController.add(msg));
    } else if (serverPushString.startsWith(pingPrefix)) {
      sendPong();
    }
  }

  void _setServerInfo(String serverInfoString,
      {ConnectionOptions connectionOptions}) {
    try {
      Map<String, dynamic> map = jsonDecode(serverInfoString);
      _serverInfo.serverId = map["server_id"];
      _serverInfo.version = map["version"];
      _serverInfo.protocolVersion = map["proto"];
      _serverInfo.goVersion = map["go"];
      _serverInfo.host = map["host"];
      _serverInfo.port = map["port"];
      _serverInfo.maxPayload = map["max_payload"];
      _serverInfo.clientId = map["client_id"];
      if (connectionOptions != null) {
        _sendConnectionPacket(connectionOptions);
      }
    } catch (ex) {
      print(ex.toString());
    }
  }

  void _sendConnectionPacket(ConnectionOptions opts) {
    var messageBuffer = CONNECT +
        "{\"verbose\":${opts.verbose},\"pedantic\":${opts.pedantic},\"tls_required\":${opts.tlsRequired},\"name\":${opts.name},\"lang\":${opts.language},\"version\":${opts.version},\"protocol\":${opts.protocol}, \"user\":${opts.userName}, \"pass\":${opts.password}}" +
        CR_LF;
    print("Writing connection message $messageBuffer");
    _socket.write(messageBuffer);
  }

  void sendPong() {
    _socket.write("$PONG$CR_LF");
  }

  /// Publishes the [message] to the [subject] with an optional [replyTo] set to receive the response
  /// ```dart
  /// var client = NatsClient("localhost", 4222);
  /// await client.connect();
  /// client.publish("Hello World", "foo-topic");
  /// client.publish("Hello World", "foo-topic", replyTo: "reply-topic");
  /// ```
  void publish(String message, String subject, {String replyTo}) {
    if (_socket == null) {
      throw Exception(
          "Socket not ready. Please check if NatsClient.connect() is called");
    }

    String messageBuffer;

    int length = message.length;

    if (replyTo != null) {
      messageBuffer = "$PUB $subject $replyTo $length $CR_LF$message$CR_LF";
    } else {
      messageBuffer = "$PUB $subject $length $CR_LF$message$CR_LF";
    }
    try {
      _socket.write(messageBuffer);
    } catch (ex) {
      print(ex);
    }
  }

  NatsMessage convertToMessage(String serverPushString) {
    var message = NatsMessage();
    List<String> lines = serverPushString.split(CR_LF);
    List<String> firstLineParts = lines[0].split(" ");

    message.subject = firstLineParts[0];
    message.sid = firstLineParts[1];

    bool replySubjectPresent = firstLineParts.length == 4;

    if (replySubjectPresent) {
      message.replyTo = firstLineParts[2];
      message.length = int.parse(firstLineParts[3]);
    } else {
      message.length = int.parse(firstLineParts[2]);
    }

    message.payload = lines[1];
    return message;
  }

  List<NatsMessage> _convertToMessages(String serverPushString) =>
      serverPushString
          .split(MSG)
          .where((msg) => msg.length > 0)
          .map((msg) => convertToMessage(msg))
          .toList();

  /// Subscribes to the [subject] with a given [subscriberId] and an optional [queueGroup] set to group the responses
  /// ```dart
  /// var client = NatsClient("localhost", 4222);
  /// await client.connect();
  /// var messageStream = client.subscribe("sub-1", "foo-topic"); // No [queueGroup] set
  /// var messageStream = client.subscribe("sub-1", "foo-topic", queueGroup: "group-1")
  ///
  /// messageStream.listen((message) {
  ///   // Do something awesome
  /// });
  /// ```
  Stream<NatsMessage> subscribe(String subscriberId, String subject,
      {String queueGroup}) {
    if (_socket == null) {
      throw Exception(
          "Socket not ready. Please check if NatsClient.connect() is called");
    }
    String messageBuffer;

    if (queueGroup != null) {
      messageBuffer = "$SUB $subject $queueGroup $subscriberId$CR_LF";
    } else {
      messageBuffer = "$SUB $subject $subscriberId$CR_LF";
    }

    _socket.write(messageBuffer);
    return _messagesController.stream.where((msg) => msg.subject == subject);
  }

  void unsubscribe(String subscriberId, {int waitUntilMessageCount}) {
    if (_socket == null) {
      throw Exception(
          "Socket not ready. Please check if NatsClient.connect() is called");
    }
    String messageBuffer;

    if (waitUntilMessageCount != null) {
      messageBuffer = "$UNSUB $subscriberId $waitUntilMessageCount$CR_LF";
    } else {
      messageBuffer = "$UNSUB $subscriberId$CR_LF";
    }
    _socket.write(messageBuffer);
  }
}
