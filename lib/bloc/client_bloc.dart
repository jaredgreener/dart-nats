import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:flutter_nats/common/connection_options.dart';
import 'package:flutter_nats/common/constants.dart';
import 'package:flutter_nats/controllers/nats_controller.dart';
import 'package:flutter_nats/models/server_info.dart';
import 'package:flutter_nats/models/subscription.dart';
import 'package:flutter_nats/models/nats_message.dart';
import 'package:logging/logging.dart';
import 'package:flutter_nats/controllers/client_controller.dart';
import './bloc.dart';
import 'package:flutter_nats/models/tcp_client.dart';

class ClientBloc extends Bloc<ClientEvent, ClientState> {

  String _currentHost;
  int _currentPort;
  int _currentSubscriptionID = 1;

  Socket? _socket;
  TcpClient? _tcpClient;
  late ServerInfo _serverInfo;

  StreamController<NatsMessage>? _messageStream;
  Map<String, Subscription> _subscriptions = {};

  StreamSubscription? _tcpListener;
  ConnectionOptions _connectionOptions;
  Logger _logger = Logger("FlutterNats");

  NATS_STATUS _currentStatus = NATS_STATUS.UNINITIALIZED;
  get status => _currentStatus;

  ClientBloc(this._currentHost, this._currentPort, {connectionOptions, Level logLevel = Level.INFO})
      : _connectionOptions = connectionOptions, super(InitialClientState()){

    print("host");
    print(_currentHost+":"+_currentPort.toString());
    Logger.root.level = logLevel;
    Logger.root.onRecord.listen((LogRecord rec) {
      print('${rec.level.name}: ${rec.time}: ${rec.message}');
    });

  }

  @override
  Stream<ClientState> mapEventToState(
    ClientEvent event,
  ) async* {

    if(event is Initialize){
      _serverInfo = ServerInfo();
      _messageStream = new StreamController.broadcast();
      _currentStatus = NATS_STATUS.INITIALIZED;
      print(_currentHost+":"+_currentPort.toString());
      _tcpClient = TcpClient(host: _currentHost, port: _currentPort);

    }else if(event is Connect){
      _logger.fine("CONNECTING!");
      await connectHelper(onConnect: event.onConnect);
    }else if(event is DataReceived){
      await dataReceivedHelper(event);
    }else if(event is SetServerInfo){

      ClientController.setServerInfo(_logger, event.info, _serverInfo);
      if (_connectionOptions != null) {
        this.add(SendConnectionOptions(_connectionOptions));
      }

    }else if(event is Publish) {

      if (_socket == null) {
        throw Exception("Socket not ready.");
      }
      NatsController.publish(_socket!, _logger, event.message, event.subject, replyTo: event.replyTo, onError: (err){
        throw Exception(err);
      });

    }else if(event is Subscribe){

      if (_socket == null) {
        throw Exception("Socket not ready.");
      }else {
        int _subscriptionID;

        if (_subscriptions.containsKey(event.subject)) {
          _subscriptionID = _subscriptions[event.subject]!.subscriptionID;
        } else {
          _subscriptionID = _currentSubscriptionID;
          _currentSubscriptionID++;
        }
        _subscriptions[event.subject] =
            Subscription(event.subject, _subscriptionID, event.onMessage);

        NatsController.subscribe(_socket!, _logger, event.subject, _subscriptionID,
            onDone: () {

              if (_subscriptions[event.subject]!.listener != null) {
                _subscriptions[event.subject]!.listener!.cancel();
              }

              _subscriptions[event.subject]!.listener =
                  _messageStream!.stream.where((incomingMsg) =>
                      ClientController.matchesRegex(
                          event.subject, incomingMsg.subject)).listen(
                      event.onMessage);
            },
            onError: (err) {
              _logger.fine("Error subscribing to "+event.subject + ": "+ err);
              _subscriptions.remove(event.subject);
              throw Exception(err);
            }
        );
      }
    }else if(event is UnSubscribe){

      if(!_subscriptions.containsKey(event.subject)){
        throw Exception("Subscription to '"+event.subject+"' does not exist.");
      }
      int subscriptionID = _subscriptions[event.subject]!.subscriptionID;
      NatsController.unsubscribe(_socket, _logger, subscriptionID, onDone: (){
        _subscriptions[event.subject]!.listener!.cancel();
      }, onError: (err){
        throw Exception(err);
      });

    }else if(event is SendPing){
      NatsController.ping(_socket, _logger);
    }else if(event is ReConnect){

      _logger.fine("RECONNECTING!");
      _currentStatus = NATS_STATUS.RECONNECTING;
      Timer(Duration(seconds: 3), () {
        if (_serverInfo!.serverUrls != null &&
            _serverInfo!.serverUrls.length > 0) {
          this.add(ReConnectToNextInCluster());
        } else {
          connectHelper(onConnect: (){
            this.add(ReSubscribe());
          });
        }
      });

    }else if(event is ReSubscribe){

      _subscriptions.forEach((subject, subscription) {
        _logger.fine("Resubscribing to "+subject);
        this.add(Subscribe(subject, subscription.onMessage));
      });

    }else if(event is SendConnectionOptions){
      NatsController.connect(_socket, _logger, opts: event.options);
      NatsController.ping(_socket, _logger);
    }else if(event is ReConnectToNextInCluster) {
      var urls = _serverInfo.serverUrls;
      bool isIPv6Address(String url) => url.contains("[") && url.contains("]");
      for (var url in urls) {
        _tcpClient = ClientController.createTcpClient(_logger, url, isIPv6Address);
        try {
          await connectHelper();
          _logger.info("Successfully switched client to $url now");
          this.add(ReSubscribe());
          break;
        } catch (ex) {
          _logger.fine("Tried connecting to $url but failed. Moving on");
        }
      }
    }else if(event is Close){

    }

  }

  Future<void> connectHelper({onConnect}) async {

    try {
      _socket = await _tcpClient!.connect();
      _tcpListener = utf8.decoder.bind(_socket!).listen(
              (dynamic data) {
            this.add(DataReceived(data));
          },
          onDone: () {
            this.add(ReConnect());
          }
      );
    }catch(err){
      throw Exception(err);
    }

    if(onConnect != null){
      onConnect();
    }

  }

  Future<void> dataReceivedHelper(DataReceived event) async {
    _currentStatus = NATS_STATUS.CONNECTED;

    if (event.data.startsWith(INFO)) {

      this.add(SetServerInfo(event.data.replaceFirst(INFO, "")));

    }else if (event.data.startsWith(MSG)) {

      _logger.fine("NATS RECEIVED MESSAGE: "+event.data);
      var msg = ClientController.parseNatsMessages(event.data);
      _messageStream!.add(msg);

    }else if (event.data.startsWith(PING)) {

      print("NATS RECEIVED PING");
      NatsController.pong(_socket, _logger);

    }else if (event.data.startsWith(PONG)) {

      _logger.fine("Received server PONG");

    }
    else if (event.data.startsWith(OK)) {

      _logger.fine("Received server OK");

    }else if (event.data.startsWith(ERR)) {

      _logger.warning("Received NATS error: "+event.data);
      ClientController.evaluateERRMessage(_logger, event.data);

    }else{

      _logger.warning("NATS UNKNOWN SERVER MESSAGE: "+event.data);

    }
  }
}
