/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Callback function definitions
typedef MessageCallbackFunction = bool Function(MqttMessage? message);

/// The connection handler interface class
abstract class IMqttConnectionHandler {
  /// The connection status
  MqttClientConnectionStatus get connectionStatus;

  /// Successful connection callback
  ConnectCallback? onConnected;

  /// Unsolicited disconnection callback
  DisconnectCallback? onDisconnected;

  /// Auto reconnect callback
  AutoReconnectCallback? onAutoReconnect;

  /// Auto reconnected callback
  AutoReconnectCompleteCallback? onAutoReconnected;

  /// Auto reconnect in progress
  bool? autoReconnectInProgress;

  // Server name, needed for auto reconnect.
  String? server;

  // Port number, needed for auto reconnect.
  int? port;

  // Connection message, needed for auto reconnect.
  MqttConnectMessage? connectionMessage;

  /// Callback function to handle bad certificate. if true, ignore the error.
  bool Function(dynamic certificate)? onBadCertificate;

  /// Runs the disconnection process to stop communicating
  /// with a message broker.
  MqttConnectionState disconnect();

  /// Closes a connection.
  void close();

  /// Kills all listeners from old connections.
  void stopListening();

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
