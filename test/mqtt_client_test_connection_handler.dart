/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/06/2017
 * Copyright :  S.Hamblett
 */
import 'package:mqtt_client/mqtt_client.dart';
import 'dart:async';

class TestConnectionHandlerNoSend extends MqttConnectionHandler {
  Future<ConnectionState> internalConnect(String hostname, int port,
      MqttConnectMessage message) {
    final Completer completer = new Completer();
    return completer.future;
  }

  ConnectionState disconnect() {
    return connectionState = ConnectionState.disconnected;
  }
}

class TestConnectionHandlerSend extends MqttConnectionHandler {
  List<MqttMessage> sentMessages = new List<MqttMessage>();

  Future<ConnectionState> internalConnect(String hostname, int port,
      MqttConnectMessage message) {
    final Completer completer = new Completer();
    return completer.future;
  }

  ConnectionState disconnect() {
    return connectionState = ConnectionState.disconnected;
  }

  void sendMessage(MqttMessage message) {
    print(
        "TestConnectionHandlerNoSend::send, message is ${message.toString()}");
    sentMessages.add(message);
  }
}