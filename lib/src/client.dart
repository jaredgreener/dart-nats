import 'package:rxdart/rxdart.dart';

import 'constants.dart';
import 'tcp_client.dart';
import 'server_info.dart';

import 'dart:io';
import "dart:convert";
import 'dart:async';

class NatsClient {
  String host;
  int port;

  Socket _socket;
  TcpClient tcpClient;
  ServerInfo serverInfo;

  NatsClient(String host, int port) {
    this.host = host;
    serverInfo = ServerInfo();
    tcpClient = TcpClient(host: host, port: port);
  }

  bool checkSocketReady() => _socket != null;

  void connect() async {
    _socket = await tcpClient.connect();
  }

  void _serverPushString(dynamic data) {
    String serverPushString = utf8.decode(data);
    String infoPrefix = "INFO ";

    if (serverPushString.startsWith(infoPrefix)) {
      _setServerInfo(serverPushString.replaceFirst(infoPrefix, ""));
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

  void publish(String message, String subject, {String replyTo}) {
    String messageBuffer;

    int length = message.length;
    List<int> bytes = utf8.encode(message);

    if (replyTo != null) {
      messageBuffer =
          "PUB $subject $replyTo $length $CR_LF$message$CR_LF";
    } else {
      messageBuffer = "PUB $subject $length $CR_LF$message$CR_LF";
    }

    print("$messageBuffer");
    _socket.write(messageBuffer);
  }
}
