import 'package:flutter_nats/bloc/bloc.dart';
import 'package:flutter_nats/common/connection_options.dart';
import 'package:flutter_nats/models/nats_message.dart';
import 'package:logging/logging.dart';

class NatsClient{

  final String _currentHost;
  final int _currentPort;

  late ClientBloc _clientBloc;

  NatsClient(
      currentHost,
      currentPort,
      {
        required ConnectionOptions connectionOptions,
        required Function onConnect,
        Level logLevel = Level.INFO
      }
  ) : assert(currentHost != null, currentPort != null), _currentHost = currentHost, _currentPort = currentPort
  {

    _clientBloc = ClientBloc(_currentHost, _currentPort, connectionOptions: connectionOptions, logLevel: logLevel);
    _clientBloc.add(Initialize());

  }

  void connect({required void onConnect()}){
    _clientBloc.add(Connect(onConnect));
  }

  void subscribe(String subject, void onMessage(NatsMessage message)){
    _clientBloc.add(Subscribe(subject, onMessage));
  }

  void unsubscribe(String subject){
    _clientBloc.add(UnSubscribe(subject));
  }

  void publish(String subject, String message){
    _clientBloc.add(Publish(subject, message));
  }

  void close(){
    _clientBloc.add(Close());
    _clientBloc.close();
  }
}