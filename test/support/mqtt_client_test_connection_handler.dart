/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/06/2017
 * Copyright :  S.Hamblett
 */
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';

class TestConnectionHandlerNoSend extends MqttConnectionHandler {
  @override
  Future<MqttClientConnectionStatus> internalConnect(
      String hostname, int port, MqttConnectMessage message) {
    final completer =
        Completer<MqttClientConnectionStatus>();
    return completer.future;
  }

  @override
  MqttConnectionState disconnect() =>
      connectionStatus.state = MqttConnectionState.disconnected;
}

class TestConnectionHandlerSend extends MqttConnectionHandler {
  List<MqttMessage> sentMessages = <MqttMessage>[];

  @override
  Future<MqttClientConnectionStatus> internalConnect(
      String hostname, int port, MqttConnectMessage message) {
    final completer =
        Completer<MqttClientConnectionStatus>();
    return completer.future;
  }

  @override
  MqttConnectionState disconnect() =>
      connectionStatus.state = MqttConnectionState.disconnected;

  @override
  void sendMessage(MqttMessage message) {
    print(
        'TestConnectionHandlerNoSend::send, message is ${message.toString()}');
    sentMessages.add(message);
  }
}
