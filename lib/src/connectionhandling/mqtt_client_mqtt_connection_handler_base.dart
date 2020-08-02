/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/03/2020
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

///  This class provides shared connection functionality
///  to serverand browser connection handler implementations.
abstract class MqttConnectionHandlerBase implements IMqttConnectionHandler {
  /// Initializes a new instance of the [MqttConnectionHandlerBase] class.
  MqttConnectionHandlerBase(this.clientEventBus,
      {@required this.maxConnectionAttempts});

  /// Successful connection callback.
  @override
  ConnectCallback onConnected;

  /// Unsolicited disconnection callback.
  @override
  DisconnectCallback onDisconnected;

  /// Auto reconnect callback
  @override
  AutoReconnectCallback onAutoReconnect;

  /// Auto reconnect in progress
  @override
  bool autoReconnectInProgress = false;

  // Server name, needed for auto reconnect.
  @override
  String server;

  // Port number, needed for auto reconnect.
  @override
  int port;

  // Connection message, needed for auto reconnect.
  @override
  MqttConnectMessage connectionMessage;

  /// Callback function to handle bad certificate. if true, ignore the error.
  @override
  bool Function(dynamic certificate) onBadCertificate;

  /// Max connection attempts
  final int maxConnectionAttempts;

  /// The broker connection acknowledgment timer
  @protected
  MqttCancellableAsyncSleep connectTimer;

  /// The event bus
  @protected
  events.EventBus clientEventBus;

  /// User supplied websocket protocols
  @protected
  List<String> websocketProtocols;

  /// The connection
  @protected
  dynamic connection;

  /// Registry of message processors
  @protected
  Map<MqttMessageType, MessageCallbackFunction> messageProcessorRegistry =
      <MqttMessageType, MessageCallbackFunction>{};

  /// Registry of sent message callbacks
  @protected
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

  /// Connect to the specific Mqtt Connection internally.
  @protected
  Future<MqttClientConnectionStatus> internalConnect(
      String hostname, int port, MqttConnectMessage message);

  /// Auto reconnect
  @protected
  void autoReconnect(AutoReconnect reconnectEvent) async {
    // If already in progress exit
    if (autoReconnectInProgress) {
      return;
    }
    autoReconnectInProgress = true;
    // If the auto reconnect callback is set call it
    if (onAutoReconnect != null) {
      onAutoReconnect();
    }

    // If we are connected disconnect from the broker. This will trigger
    // the on done disconnection processing.
    if (reconnectEvent.wasConnected) {
      sendMessage(MqttDisconnectMessage());
    } else {
      // Force a disconnect
      connection.disconnect(auto: true);
    }

    connection.onDisconnected = null;
    MqttLogger.log(
        'MqttConnectionHandlerBase::autoReconnect - attempting reconnection');
    connectionStatus = await internalConnect(server, port, connectionMessage);
    autoReconnectInProgress = false;
    MqttLogger.log(
        'MqttConnectionHandler::autoReconnect - auto reconnect complete');
  }

  /// Sends a message to the broker through the current connection.
  @override
  void sendMessage(MqttMessage message) {
    MqttLogger.log('MqttConnectionHandlerBase::sendMessage - $message');
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
  @protected
  void messageAvailable(MessageAvailable event) {
    final callback = messageProcessorRegistry[event.message.header.messageType];
    callback(event.message);
  }

  /// Disconnects
  @override
  MqttConnectionState disconnect() {
    MqttLogger.log('SynchronousMqttServerConnectionHandler::disconnect');
    if (connectionStatus.state == MqttConnectionState.connected) {
      // Send a disconnect message to the broker
      sendMessage(MqttDisconnectMessage());
    }
    // Disconnect
    _performConnectionDisconnect();
    return connectionStatus.state;
  }

  /// Disconnects the underlying connection object.
  @protected
  void _performConnectionDisconnect() {
    connectionStatus.state = MqttConnectionState.disconnected;
  }

  /// Processes the connect acknowledgement message.
  @protected
  bool connectAckProcessor(MqttMessage msg) {
    MqttLogger.log(
        'SynchronousMqttServerConnectionHandler::_connectAckProcessor');
    try {
      final MqttConnectAckMessage ackMsg = msg;
      // Drop the connection if our connect request has been rejected.
      if (ackMsg.variableHeader.returnCode ==
              MqttConnectReturnCode.brokerUnavailable ||
          ackMsg.variableHeader.returnCode ==
              MqttConnectReturnCode.identifierRejected ||
          ackMsg.variableHeader.returnCode ==
              MqttConnectReturnCode.unacceptedProtocolVersion ||
          ackMsg.variableHeader.returnCode ==
              MqttConnectReturnCode.notAuthorized ||
          ackMsg.variableHeader.returnCode ==
              MqttConnectReturnCode.badUsernameOrPassword) {
        MqttLogger.log(
            'SynchronousMqttServerConnectionHandler::_connectAckProcessor '
            'connection rejected');
        connectionStatus.returnCode = ackMsg.variableHeader.returnCode;
        _performConnectionDisconnect();
      } else {
        // Initialize the keepalive to start the ping based keepalive process.
        MqttLogger.log(
            'SynchronousMqttServerConnectionHandler::_connectAckProcessor '
            '- state = connected');
        connectionStatus.state = MqttConnectionState.connected;
        connectionStatus.returnCode = MqttConnectReturnCode.connectionAccepted;
        // Call the connected callback if we have one
        if (onConnected != null) {
          onConnected();
        }
      }
    } on Exception {
      _performConnectionDisconnect();
    }
    // Cancel the connect timer;
    MqttLogger.log(
        'SynchronousMqttServerConnectionHandler:: cancelling connect timer');
    connectTimer.cancel();
    return true;
  }

  /// Initialise the event listeners;
  void initialiseListeners() {
    clientEventBus.on<AutoReconnect>().listen(autoReconnect);
    clientEventBus.on<MessageAvailable>().listen(messageAvailable);
  }
}
