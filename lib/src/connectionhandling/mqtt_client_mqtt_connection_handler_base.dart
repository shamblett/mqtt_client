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
      {required this.maxConnectionAttempts});

  /// Successful connection callback.
  @override
  ConnectCallback? onConnected;

  /// Unsolicited disconnection callback.
  @override
  DisconnectCallback? onDisconnected;

  /// Auto reconnect callback
  @override
  AutoReconnectCallback? onAutoReconnect;

  /// Auto reconnected callback
  @override
  AutoReconnectCompleteCallback? onAutoReconnected;

  /// Auto reconnect in progress
  @override
  bool? autoReconnectInProgress = false;

  // Server name, needed for auto reconnect.
  @override
  String? server;

  // Port number, needed for auto reconnect.
  @override
  int? port;

  // Connection message, needed for auto reconnect.
  @override
  MqttConnectMessage? connectionMessage;

  /// Callback function to handle bad certificate. if true, ignore the error.
  @override
  bool Function(dynamic certificate)? onBadCertificate;

  /// Max connection attempts
  final int? maxConnectionAttempts;

  /// The broker connection acknowledgment timer
  @protected
  late MqttCancellableAsyncSleep connectTimer;

  /// The event bus
  @protected
  events.EventBus? clientEventBus;

  /// User supplied websocket protocols
  @protected
  List<String>? websocketProtocols;

  /// The connection
  @protected
  late dynamic connection;

  /// Registry of message processors
  @protected
  Map<MqttMessageType, MessageCallbackFunction?> messageProcessorRegistry =
      <MqttMessageType, MessageCallbackFunction?>{};

  /// Registry of sent message callbacks
  @protected
  List<MessageCallbackFunction> sentMessageCallbacks =
      <MessageCallbackFunction>[];

  /// We have had an initial connection
  @protected
  bool initialConnectionComplete = false;

  /// Connection status
  @override
  MqttClientConnectionStatus connectionStatus = MqttClientConnectionStatus();

  /// Connect to the specific Mqtt Connection.
  @override
  Future<MqttClientConnectionStatus> connect(
      String? server, int? port, MqttConnectMessage? message) async {
    // Save the parameters for auto reconnect.
    this.server = server;
    this.port = port;
    MqttLogger.log(
        'MqttConnectionHandlerBase::connect - server $server, port $port');
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
      String? hostname, int? port, MqttConnectMessage? message);

  /// Auto reconnect
  @protected
  void autoReconnect(AutoReconnect reconnectEvent) async {
    MqttLogger.log('MqttConnectionHandlerBase::autoReconnect entered');
    // If already in progress exit and we were not connected return
    if (autoReconnectInProgress! && !reconnectEvent.wasConnected) {
      return;
    }
    autoReconnectInProgress = true;
    // If the auto reconnect callback is set call it
    if (onAutoReconnect != null) {
      onAutoReconnect!();
    }

    // If we are connected disconnect from the broker.
    if (reconnectEvent.wasConnected) {
      MqttLogger.log(
          'MqttConnectionHandlerBase::autoReconnect - was connected, sending disconnect');
      sendMessage(MqttDisconnectMessage());
      connectionStatus.state = MqttConnectionState.disconnecting;
    }
    connection.disconnect(auto: true);
    connection.onDisconnected = null;
    MqttLogger.log(
        'MqttConnectionHandlerBase::autoReconnect - attempting reconnection');
    connectionStatus = await connect(server, port, connectionMessage);
    autoReconnectInProgress = false;
    if (connectionStatus.state == MqttConnectionState.connected) {
      connection.onDisconnected = onDisconnected;
      // Fire the re subscribe event.
      clientEventBus!.fire(Resubscribe(fromAutoReconnect: true));
      MqttLogger.log(
          'MqttConnectionHandlerBase::autoReconnect - auto reconnect complete');
      // If the auto reconnect callback is set call it
      if (onAutoReconnected != null) {
        onAutoReconnected!();
      }
    } else {
      MqttLogger.log(
          'MqttConnectionHandlerBase::autoReconnect - auto reconnect failed - re trying');
      clientEventBus!.fire(AutoReconnect());
    }
  }

  /// Sends a message to the broker through the current connection.
  @override
  void sendMessage(MqttMessage? message) {
    MqttLogger.log('MqttConnectionHandlerBase::sendMessage - ', message);
    if ((connectionStatus.state == MqttConnectionState.connected) ||
        (connectionStatus.state == MqttConnectionState.connecting)) {
      final buff = typed.Uint8Buffer();
      final stream = MqttByteBuffer(buff);
      message!.writeTo(stream);
      stream.seek(0);
      connection.send(stream);
      // Let any registered people know we're doing a message.
      for (final callback in sentMessageCallbacks) {
        callback(message);
      }
    } else {
      MqttLogger.log('MqttConnectionHandlerBase::sendMessage - not connected');
    }
  }

  /// Closes the connection to the Mqtt message broker.
  @override
  void close() {
    if (connectionStatus.state == MqttConnectionState.connected) {
      disconnect();
    }
  }

  @override
  void stopListening() {
    connection.stopListening();
  }

  /// Registers for the receipt of messages when they arrive.
  @override
  void registerForMessage(
      MqttMessageType msgType, MessageCallbackFunction? callback) {
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
    final messageType = event.message!.header!.messageType;
    MqttLogger.log(
        'MqttConnectionHandlerBase::messageAvailable - message type is $messageType');
    final callback = messageProcessorRegistry[messageType!];
    if (callback != null) {
      callback(event.message);
    } else {
      MqttLogger.log(
          'MqttConnectionHandlerBase::messageAvailable - WARN - no registered callback for this message type');
    }
  }

  /// Disconnects
  @override
  MqttConnectionState disconnect() {
    MqttLogger.log('MqttConnectionHandlerBase::disconnect - entered');
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
    MqttLogger.log(
        'MqttConnectionHandlerBase::_performConnectionDisconnect entered');
    connectionStatus.state = MqttConnectionState.disconnected;
  }

  /// Processes the connect acknowledgement message.
  @protected
  bool connectAckProcessor(MqttMessage msg) {
    MqttLogger.log('MqttConnectionHandlerBase::_connectAckProcessor');
    try {
      final ackMsg = msg as MqttConnectAckMessage;
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
        MqttLogger.log('MqttConnectionHandlerBase::_connectAckProcessor '
            'connection rejected');
        connectionStatus.returnCode = ackMsg.variableHeader.returnCode;
        _performConnectionDisconnect();
      } else {
        // Initialize the keepalive to start the ping based keepalive process.
        MqttLogger.log('MqttConnectionHandlerBase:_connectAckProcessor '
            '- state = connected');
        connectionStatus.state = MqttConnectionState.connected;
        connectionStatus.returnCode = MqttConnectReturnCode.connectionAccepted;
        // Call the connected callback if we have one
        if (onConnected != null) {
          onConnected!();
        }
      }
    } on Exception {
      _performConnectionDisconnect();
    }
    // Cancel the connect timer;
    MqttLogger.log('MqttConnectionHandlerBase:: cancelling connect timer');
    connectTimer.cancel();
    return true;
  }

  /// Connect acknowledge recieved
  void connectAckReceived(ConnectAckMessageAvailable event) {
    connectAckProcessor(event.message!);
  }

  /// Initialise the event listeners;
  void initialiseListeners() {
    clientEventBus!.on<AutoReconnect>().listen(autoReconnect);
    clientEventBus!.on<MessageAvailable>().listen(messageAvailable);
    clientEventBus!.on<ConnectAckMessageAvailable>().listen(connectAckReceived);
  }
}
