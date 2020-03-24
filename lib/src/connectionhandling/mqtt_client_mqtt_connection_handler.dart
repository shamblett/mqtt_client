/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_server_client;

///  This class provides shared connection functionality
///  to connection handler implementations.
abstract class MqttConnectionHandler implements IMqttConnectionHandler {
  /// Initializes a new instance of the MqttConnectionHandler class.
  MqttConnectionHandler();

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

  /// The connection
  dynamic connection;

  /// Registry of message processors
  Map<MqttMessageType, MessageCallbackFunction> messageProcessorRegistry =
      <MqttMessageType, MessageCallbackFunction>{};

  /// Registry of sent message callbacks
  List<MessageCallbackFunction> sentMessageCallbacks =
      <MessageCallbackFunction>[];

  /// Connection status
  @override
  MqttClientConnectionStatus connectionStatus = MqttClientConnectionStatus();

  /// Connect to the specific Mqtt Connection.
  @override
  Future<MqttClientConnectionStatus> connect(
      String server, int port, MqttConnectMessage message) async {
    // Save the parameters for auto reconnect.
    this.server = server;
    this.port = port;
    // ignore: unnecessary_this
    this.connectionMessage = message;
    try {
      await internalConnect(server, port, message);
      return connectionStatus;
    } on Exception {
      connectionStatus.state = MqttConnectionState.faulted;
      rethrow;
    }
  }

  /// Connect to the specific Mqtt Connection.
  Future<MqttClientConnectionStatus> internalConnect(
      String hostname, int port, MqttConnectMessage message);

  /// Auto reconnect
  void autoReconnect(AutoReconnect reconnectEvent) async {
    // Check if user requested, if not do not auto reconnect if we are
    // connected.
    if (!reconnectEvent.userRequested) {
      // Check the connection state, if connected do nothing
      if (connectionStatus.state == MqttConnectionState.connected) {
        MqttLogger.log(
            'MqttConnectionHandler::autoReconnect - connected and not user '
            'requested, exiting');
        return;
      }
    }
    // If the auto reconnect callback is set call it
    if (onAutoReconnect != null) {
      onAutoReconnect();
    }
    // Disconnect and call internal connect indefinitely
    while (connectionStatus.state != MqttConnectionState.connected) {
      MqttLogger.log(
          'MqttConnectionHandler::autoReconnect - attempting reconnection');
      connection.disconnect(auto: true);
      await internalConnect(server, port, connectionMessage);
    }
    MqttLogger.log('MqttConnectionHandler::autoReconnect - reconnected');
  }

  /// Sends a message to the broker through the current connection.
  @override
  void sendMessage(MqttMessage message) {
    MqttLogger.log('MqttConnectionHandler::sendMessage - $message');
    if ((connectionStatus.state == MqttConnectionState.connected) ||
        (connectionStatus.state == MqttConnectionState.connecting)) {
      final buff = typed.Uint8Buffer();
      final stream = MqttByteBuffer(buff);
      message.writeTo(stream);
      stream.seek(0);
      connection.send(stream);
      // Let any registered people know we're doing a message.
      for (final callback in sentMessageCallbacks) {
        callback(message);
      }
    } else {
      MqttLogger.log('MqttConnectionHandler::sendMessage - not connected');
    }
  }

  /// Closes the connection to the Mqtt message broker.
  @override
  void close() {
    if (connectionStatus.state == MqttConnectionState.connected) {
      disconnect();
    }
  }

  /// Registers for the receipt of messages when they arrive.
  @override
  void registerForMessage(
      MqttMessageType msgType, MessageCallbackFunction callback) {
    messageProcessorRegistry[msgType] = callback;
  }

  /// UnRegisters for the receipt of messages when they arrive.
  @override
  void unRegisterForMessage(MqttMessageType msgType) {
    messageProcessorRegistry.remove(msgType);
  }

  /// Registers a callback to be called whenever a message is sent.
  @override
  void registerForAllSentMessages(MessageCallbackFunction sentMsgCallback) {
    sentMessageCallbacks.add(sentMsgCallback);
  }

  /// UnRegisters a callback that is called whenever a message is sent.
  @override
  void unRegisterForAllSentMessages(MessageCallbackFunction sentMsgCallback) {
    sentMessageCallbacks.remove(sentMsgCallback);
  }

  /// Handles the Message Available event of the connection control for
  /// handling non connection messages.
  void messageAvailable(MessageAvailable event) {
    final callback = messageProcessorRegistry[event.message.header.messageType];
    callback(event.message);
  }
}
