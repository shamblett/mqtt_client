/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Callback function definitions
typedef MessageCallbackFunction = bool Function(MqttMessage message);

/// The connection handler interface class
abstract class IMqttConnectionHandler {
  /// The connection status
  MqttClientConnectionStatus get connectionStatus;

  /// Use a websocket rather than TCP
  bool useWebSocket = false;

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
  bool useAlternateWebSocketImplementation = false;

  /// User supplied websocket protocols
  List<String> websocketProtocols;

  /// If set use a secure connection, note TCP only, not websocket.
  bool secure = false;

  /// The security context for secure usage
  dynamic securityContext;

  /// Successful connection callback
  ConnectCallback onConnected;

  /// Unsolicited disconnection callback
  DisconnectCallback onDisconnected;

  /// Callback function to handle bad certificate. if true, ignore the error.
  bool Function(dynamic certificate) onBadCertificate;

  /// Runs the disconnection process to stop communicating
  /// with a message broker.
  MqttConnectionState disconnect();

  /// Closes a connection.
  void close();

  /// Connects to a message broker
  /// The broker server to connect to
  /// The port to connect to
  /// The connect message to use to initiate the connection
  Future<MqttClientConnectionStatus> connect(
      String server, int port, MqttConnectMessage message);

  /// Register the specified callback to receive messages of a specific type.
  /// The type of message that the callback should be sent
  /// The callback function that will accept the message type
  void registerForMessage(
      MqttMessageType msgType, MessageCallbackFunction msgProcessorCallback);

  ///  Sends a message to a message broker.
  void sendMessage(MqttMessage message);

  /// Unregisters the specified callbacks so it not longer receives
  /// messages of the specified type.
  /// The message type the callback currently receives
  void unRegisterForMessage(MqttMessageType msgType);

  /// Registers a callback to be executed whenever a message is
  /// sent by the connection handler.
  void registerForAllSentMessages(MessageCallbackFunction sentMsgCallback);

  /// UnRegisters a callback that is registerd to be executed whenever a
  /// message is sent by the connection handler.
  void unRegisterForAllSentMessages(MessageCallbackFunction sentMsgCallback);
}
