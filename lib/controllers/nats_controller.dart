import 'dart:io';
import '../common/constants.dart';
import '../common/connection_options.dart';
import 'package:logging/logging.dart';

class NatsController {

  static void connect(Socket? socket, Logger log, {required ConnectionOptions opts}) {
    if(socket != null) {
      var messageBuffer = CONNECT +
          "{\"verbose\":${opts.verbose},\"pedantic\":${opts
              .pedantic},\"tls_required\":${opts.tlsRequired},\"name\":${opts
              .name},\"lang\":${opts.language},\"version\":${opts
              .version},\"protocol\":${opts.protocol}, \"user\":${opts
              .userName}, \"pass\":${opts.password}}" +
          CR_LF;
      log.finer("Sending CONNECT to NATS Server : " + messageBuffer);
      socket.write(messageBuffer);
    }
  }

  static void publish(Socket socket, Logger log, String message, String subject, {void onDone()?, void onError(Exception ex)?, String? replyTo}) {

    String messageBuffer;

    int length = message.length;

    if (replyTo != null) {
      messageBuffer = "$PUB $subject $replyTo $length $CR_LF$message$CR_LF";
    } else {
      messageBuffer = "$PUB $subject $length $CR_LF$message$CR_LF";
    }
    try {
      socket.write(messageBuffer);
      if(onDone != null) { onDone(); }
    } catch (ex) {
      log.severe(ex);
      if(onError != null){ onError(ex as Exception); }
    }
  }

  static void subscribe(Socket socket, Logger log, String subject, int subscriptionID, {String? queueGroup, void onDone()?, void onError(er)?}) {

    String messageBuffer = "$SUB $subject "+subscriptionID.toString()+"$CR_LF";

    try {
      socket.write(messageBuffer);
      if(onDone != null){ onDone(); }
    } catch (ex) {
      log.severe("Error while creating subscription: $ex");
      if(onError != null){ onError(ex); }
    }
  }

  static void unsubscribe(Socket? socket, Logger log, int subscriberId, {int? waitUntilMessageCount, required void onDone(), required void onError(Exception ex)}) {

    String messageBuffer;

    if (waitUntilMessageCount != null) {
      messageBuffer = "$UNSUB "+subscriberId.toString()+" $waitUntilMessageCount$CR_LF";
    } else {
      messageBuffer = "$UNSUB "+subscriberId.toString()+"$CR_LF";
    }

    try {
      socket!.write(messageBuffer);
      onDone();
    } catch (ex) {
      log.severe("Error while unsubscribing $subscriberId");
      onError(ex as Exception);
    }
  }

  static void pong(Socket? socket, Logger log) {
    if(socket != null) {
      log.fine("NATS SENDING PONG");
      socket.write("$PONG$CR_LF");
    }
  }

  static void ping(Socket? _socket, Logger log) {
    log.fine("NATS SENDING PING");
    if(_socket != null) {
      _socket.write("$PING$CR_LF");
    }
  }
}
