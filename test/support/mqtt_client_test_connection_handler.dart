/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/06/2017
 * Copyright :  S.Hamblett
 */
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class TestConnectionHandlerNoSend extends MqttConnectionHandler {
  /// Auto reconnect callback
  @override
  AutoReconnectCallback onAutoReconnect;

  /// Use a websocket rather than TCP
  @override
  bool useWebSocket = false;

  // Server name, needed for auto reconnect.
  @override
  String server;

  // Port number, needed for auto reconnect.
  @override
  int port;

  // Connection message, needed for auto reconnect.
  @override
  MqttConnectMessage connectionMessage;

  /// Alternate websocket implementation.
  ///
  /// The Amazon Web Services (AWS) IOT MQTT interface(and maybe others)
  /// has a bug that causes it not to connect if unexpected message headers are
  /// present in the initial GET message during the handshake.
  /// Since the httpclient classes insist on adding those headers, an alternate
  /// method is used to perform the handshake.
  /// After the handshake everything goes back to the normal websocket class.
  /// Only use this websocket implementation if you know it is needed
  /// by your broker.
  @override
  bool useAlternateWebSocketImplementation = false;

  /// User supplied websocket protocols
  @override
  List<String> websocketProtocols;

  /// If set use a secure connection, note TCP only, not websocket.
  @override
  bool secure = false;

  /// The security context for secure usage
  @override
  dynamic securityContext;

  /// Successful connection callback
  @override
  ConnectCallback onConnected;

  /// Unsolicited disconnection callback
  @override
  DisconnectCallback onDisconnected;

  /// Callback function to handle bad certificate. if true, ignore the error.
  @override
  bool Function(dynamic certificate) onBadCertificate;

  @override
  Future<MqttClientConnectionStatus> internalConnect(
      String hostname, int port, MqttConnectMessage message) {
    final completer = Completer<MqttClientConnectionStatus>();
    return completer.future;
  }

  @override
  MqttConnectionState disconnect() =>
      connectionStatus.state = MqttConnectionState.disconnected;
}

class TestConnectionHandlerSend extends MqttConnectionHandler {
  // Server name, needed for auto reconnect.
  @override
  String server;

  // Port number, needed for auto reconnect.
  @override
  int port;

  // Connection message, needed for auto reconnect.
  @override
  MqttConnectMessage connectionMessage;

  /// Use a websocket rather than TCP
  @override
  bool useWebSocket = false;

  /// Auto reconnect callback
  @override
  AutoReconnectCallback onAutoReconnect;

  /// Alternate websocket implementation.
  ///
  /// The Amazon Web Services (AWS) IOT MQTT interface(and maybe others)
  /// has a bug that causes it not to connect if unexpected message headers are
  /// present in the initial GET message during the handshake.
  /// Since the httpclient classes insist on adding those headers, an alternate
  /// method is used to perform the handshake.
  /// After the handshake everything goes back to the normal websocket class.
  /// Only use this websocket implementation if you know it is needed
  /// by your broker.
  @override
  bool useAlternateWebSocketImplementation = false;

  /// User supplied websocket protocols
  @override
  List<String> websocketProtocols;

  /// If set use a secure connection, note TCP only, not websocket.
  @override
  bool secure = false;

  /// The security context for secure usage
  @override
  dynamic securityContext;

  /// Successful connection callback
  @override
  ConnectCallback onConnected;

  /// Unsolicited disconnection callback
  @override
  DisconnectCallback onDisconnected;

  /// Callback function to handle bad certificate. if true, ignore the error.
  @override
  bool Function(dynamic certificate) onBadCertificate;
  List<MqttMessage> sentMessages = <MqttMessage>[];

  @override
  Future<MqttClientConnectionStatus> internalConnect(
      String hostname, int port, MqttConnectMessage message) {
    final completer = Completer<MqttClientConnectionStatus>();
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
