import 'package:rxdart/rxdart.dart';

import 'constants.dart';
import 'tcp_client.dart';
import 'server_info.dart';
import 'nats_message.dart';

import 'dart:io';
import "dart:convert";
import 'dart:async';

class NatsClient {
  String host;
  int port;

  Socket _socket;
  TcpClient tcpClient;
  ServerInfo serverInfo;

  StreamController<NatsMessage> messagesController;

  NatsClient(String host, int port) {
    this.host = host;
    serverInfo = ServerInfo();
    messagesController = new StreamController.broadcast();
    tcpClient = TcpClient(host: host, port: port);
  }

  bool checkSocketReady() => _socket != null;

  void connect() async {
    _socket = await tcpClient.connect();
    _socket.transform(utf8.decoder).listen((data) {
      _serverPushString(data);
    });
  }

  void _serverPushString(String serverPushString) {
    String infoPrefix = "INFO ";
    String messagePrefix = "MSG ";
    String pingPrefix = "PING";

    print("Received $serverPushString");

    if (serverPushString.startsWith(infoPrefix)) {
      _setServerInfo(serverPushString.replaceFirst(infoPrefix, ""));
    } else if (serverPushString.startsWith(messagePrefix)) {
      serverPushString = serverPushString.replaceFirst(messagePrefix, "");
      messagesController.add(convertToMessage(serverPushString));
    } else if (serverPushString.startsWith(pingPrefix)) {
      sendPong();
    }
  }

  void _setServerInfo(String serverInfoString) {
    print(serverInfoString);
    try {
      Map<String, dynamic> map = jsonDecode(serverInfoString);
      serverInfo.serverId = map["server_id"];
      serverInfo.version = map["version"];
      serverInfo.protocolVersion = map["proto"];
      serverInfo.goVersion = map["go"];
      serverInfo.host = map["host"];
      serverInfo.port = map["port"];
      serverInfo.maxPayload = map["max_payload"];
      serverInfo.clientId = map["client_id"];
    } catch (ex) {
      print(ex.toString());
    }
  }

  void sendPong() {
    _socket.write("PONG$CR_LF");
  }

  /// Publishes the [message] to the [subject] with an optional [replyTo] set to receive the response
  void publish(String message, String subject, {String replyTo}) {
    String messageBuffer;

    int length = message.length;

    if (replyTo != null) {
      messageBuffer = "PUB $subject $replyTo $length $CR_LF$message$CR_LF";
    } else {
      messageBuffer = "PUB $subject $length $CR_LF$message$CR_LF";
    }
    try {
      print("Writing to socket");
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

  Stream<NatsMessage> subscribe(String subscriberId, String subject,
      {String queueGroup}) {
    String messageBuffer;

    if (queueGroup != null) {
      messageBuffer = "SUB $subject $queueGroup $subscriberId$CR_LF";
    } else {
      messageBuffer = "SUB $subject $subscriberId$CR_LF";
    }
    _socket.write(messageBuffer);
    return messagesController.stream.where((msg) => msg.subject == subject);
  }
}
