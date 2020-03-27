/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_browser_client;

/// Connection handler that performs connections and disconnections
/// to the hostname in a synchronous manner.
class SynchronousMqttBrowserConnectionHandler
    extends MqttBrowserConnectionHandler {
  /// Initializes a new instance of the MqttConnectionHandler class.
  SynchronousMqttBrowserConnectionHandler(this._clientEventBus) {
    _clientEventBus.on<AutoReconnect>().listen(autoReconnect);
    registerForMessage(MqttMessageType.connectAck, _connectAckProcessor);
    _clientEventBus.on<MessageAvailable>().listen(messageAvailable);
  }

  /// The connection status
  @override
  MqttClientConnectionStatus get connectionStatus;

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
  static const int maxConnectionAttempts = 3;

  /// The broker connection acknowledgment timer
  MqttCancellableAsyncSleep _connectTimer;

  /// The event bus
  final events.EventBus _clientEventBus;

  /// Synchronously connect to the specific Mqtt Connection.
  @override
  Future<MqttClientConnectionStatus> internalConnect(
      String hostname, int port, MqttConnectMessage connectMessage) async {
    var connectionAttempts = 0;
    MqttLogger.log(
        'SynchronousMqttBrowserConnectionHandler::internalConnect entered');
    do {
      // Initiate the connection
      MqttLogger.log(
          'SynchronousMqttBrowserConnectionHandler::internalConnect - '
          'initiating connection try $connectionAttempts');
      connectionStatus.state = MqttConnectionState.connecting;
      connection = MqttBrowserWsConnection(_clientEventBus);
      connection.onDisconnected = onDisconnected;
      if (websocketProtocols != null) {
        connection.protocols = websocketProtocols;
      }

      // Connect
      _connectTimer = MqttCancellableAsyncSleep(5000);
      await connection.connect(hostname, port);
      MqttLogger.log(
          'SynchronousMqttBrowserConnectionHandler::internalConnect - '
          'connection complete');
      // Transmit the required connection message to the broker.
      MqttLogger.log('SynchronousMqttBrowserConnectionHandler::internalConnect '
          'sending connect message');
      sendMessage(connectMessage);
      MqttLogger.log(
          'SynchronousMqttBrowserConnectionHandler::internalConnect - '
          'pre sleep, state = $connectionStatus');
      // We're the sync connection handler so we need to wait for the
      // brokers acknowledgement of the connections
      await _connectTimer.sleep();
      MqttLogger.log(
          'SynchronousMqttBrowserConnectionHandler::internalConnect - '
          'post sleep, state = $connectionStatus');
    } while (connectionStatus.state != MqttConnectionState.connected &&
        ++connectionAttempts < maxConnectionAttempts);
    // If we've failed to handshake with the broker, throw an exception.
    if (connectionStatus.state != MqttConnectionState.connected) {
      MqttLogger.log(
          'SynchronousMqttBrowserConnectionHandler::internalConnect failed');
      throw NoConnectionException('The maximum allowed connection attempts '
          '({$maxConnectionAttempts}) were exceeded. '
          'The broker is not responding to the connection request message '
          '(Missing Connection Acknowledgement');
    }
    MqttLogger.log('SynchronousMqttBrowserConnectionHandler::internalConnect '
        'exited with state $connectionStatus');
    return connectionStatus;
  }

  /// Disconnects
  @override
  MqttConnectionState disconnect() {
    MqttLogger.log('SynchronousMqttBrowserConnectionHandler::disconnect');
    // Send a disconnect message to the broker
    sendMessage(MqttDisconnectMessage());
    // Disconnect
    _performConnectionDisconnect();
    return connectionStatus.state;
  }

  /// Disconnects the underlying connection object.
  void _performConnectionDisconnect() {
    connectionStatus.state = MqttConnectionState.disconnected;
  }

  /// Processes the connect acknowledgement message.
  bool _connectAckProcessor(MqttMessage msg) {
    MqttLogger.log(
        'SynchronousMqttBrowserConnectionHandler::_connectAckProcessor');
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
            'SynchronousMqttBrowserConnectionHandler::_connectAckProcessor '
            'connection rejected');
        connectionStatus.returnCode = ackMsg.variableHeader.returnCode;
        _performConnectionDisconnect();
      } else {
        // Initialize the keepalive to start the ping based keepalive process.
        MqttLogger.log(
            'SynchronousMqttBrowserConnectionHandler::_connectAckProcessor '
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
        'SynchronousMqttBrowserConnectionHandler:: cancelling connect timer');
    _connectTimer.cancel();
    return true;
  }
}
