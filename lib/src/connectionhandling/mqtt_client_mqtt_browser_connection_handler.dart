/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_browser_client;

///  This class provides shared connection functionality
///  to connection handler implementations.
abstract class MqttBrowserConnectionHandler implements IMqttConnectionHandler {
  /// Initializes a new instance of the MqttBrowserConnectionHandler class.
  MqttBrowserConnectionHandler();

  /// The connection
  dynamic connection;

  /// User supplied websocket protocols
  List<String> websocketProtocols;

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
    try {
      await internalConnect(server, port, message);
      return connectionStatus;
    } on Exception {
      connectionStatus.state = MqttConnectionState.faulted;
      rethrow;
    }
  }

  /// Auto reconnect
  void autoReconnect(AutoReconnect reconnectEvent) async {
    // Check if user requested, if not do not auto reconnect if we are
    // connected.
    if (!reconnectEvent.userRequested) {
      // Check the connection state, if connected do nothing
      if (connectionStatus.state == MqttConnectionState.connected) {
        MqttLogger.log(
            'MqttBrowserConnectionHandler::autoReconnect - connected, exiting');
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
          'MqttBrowserConnectionHandler::autoReconnect - attempting reconnection');
      connection.disconnect(auto: true);
      await internalConnect(server, port, connectionMessage);
    }
    MqttLogger.log('MqttBrowserConnectionHandler::autoReconnect - reconnected');
  }

  /// Connect to the specific Mqtt Connection.
  Future<MqttClientConnectionStatus> internalConnect(
      String hostname, int port, MqttConnectMessage message);

  /// Sends a message to the broker through the current connection.
  @override
  void sendMessage(MqttMessage message) {
    MqttLogger.log('MqttBrowserConnectionHandler::sendMessage - $message');
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
      MqttLogger.log(
          'MqttBrowserConnectionHandler::sendMessage - not connected');
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
