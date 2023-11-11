import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_nats/common/constants.dart';
import 'package:flutter_nats/models/nats_message.dart';
import 'package:flutter_nats/models/tcp_client.dart';
import 'package:logging/logging.dart';

class ClientController{

  static NatsMessage parseNatsMessage(String messageString) {
    var message = NatsMessage();
    List<String> lines = messageString.split(CR_LF);
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

  static NatsMessage parseNatsMessages(String messageString) {
    return parseNatsMessage(messageString.substring(4));
  }

  static void setServerInfo(Logger _logger, String info, _serverInfo){
    try {
      Map<String, dynamic> map = jsonDecode(info);
      _serverInfo.serverId = map["server_id"];
      _serverInfo.version = map["version"];
      _serverInfo.protocolVersion = map["proto"];
      _serverInfo.goVersion = map["go"];
      _serverInfo.host = map["host"];
      _serverInfo.port = map["port"];
      _serverInfo.maxPayload = map["max_payload"];
      _serverInfo.clientId = map["client_id"];
      try {
        if (map["connect_urls"] != null) {
          _serverInfo.serverUrls = map["connect_urls"].cast<String>();
        }
      } catch (e) {
        _logger.severe(e.toString());
      }

    } catch (ex) {
      _logger.severe(ex.toString());
    }
  }
  static void evaluateERRMessage(Logger logger, String serverPushString){
    List<String> lines = serverPushString.split(CR_LF);
    List<String> firstLineParts = lines[0].split(" ");

    if(firstLineParts[1] != null && firstLineParts[1] != ''){

      if(DISCONNECTING_ERRORS.contains(firstLineParts[1])){
        logger.warning("THIS ERROR WILL CAUSE A DISCONNECT!");
      }
      STAYOPEN_ERRORS.forEach((element) {
        if(firstLineParts[1].startsWith(element)){
          logger.warning("THIS ERROR WILL NOT CAUSE A DISCONNECT!");
        }
      });

    }
    else{
      logger.warning("Unknown Error!");
    }
  }

  static bool matchesRegex(String listeningSubject, String incomingSubject) {
    var expression = RegExp("$listeningSubject");
    return expression.hasMatch(incomingSubject);
  }

  static TcpClient createTcpClient(Logger log, String url, bool checker(String url)) {
    log.fine("Trying to connect to $url now");
    int port = int.parse(url.split(":")[url.split(":").length - 1]);
    String host;
    if (checker(url)) {
      // IPv6 address
      host = url.substring(url.indexOf("[") + 1, url.indexOf("]"));
    } else {
      // IPv4 address
      host = url.substring(0, url.indexOf(":"));
    }
    return TcpClient(host: host, port: port);
  }
}