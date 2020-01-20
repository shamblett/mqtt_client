/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_server_client;

/// Connection handler that performs connections and disconnections
/// to the hostname in a synchronous manner.
class SynchronousMqttConnectionHandler extends MqttConnectionHandler {
  /// Initializes a new instance of the MqttConnectionHandler class.
  SynchronousMqttConnectionHandler(this._clientEventBus);

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
    MqttLogger.log('SynchronousMqttConnectionHandler::internalConnect entered');
    do {
      // Initiate the connection
      MqttLogger.log('SynchronousMqttConnectionHandler::internalConnect - '
          'initiating connection try $connectionAttempts');
      connectionStatus.state = MqttConnectionState.connecting;
      if (useWebSocket) {
        if (useAlternateWebSocketImplementation) {
          MqttLogger.log('SynchronousMqttConnectionHandler::internalConnect - '
              'alternate websocket implementation selected');
          connection = MqttWs2Connection(securityContext, _clientEventBus);
        } else {
          MqttLogger.log('SynchronousMqttConnectionHandler::internalConnect - '
              'websocket selected');
          connection = MqttWsConnection(_clientEventBus);
        }
        if (websocketProtocols != null) {
          connection.protocols = websocketProtocols;
        }
      } else if (secure) {
        MqttLogger.log('SynchronousMqttConnectionHandler::internalConnect - '
            'secure selected');
        connection = MqttSecureConnection(
            securityContext, _clientEventBus, onBadCertificate);
      } else {
        MqttLogger.log('SynchronousMqttConnectionHandler::internalConnect - '
            'insecure TCP selected');
        connection = MqttNormalConnection(_clientEventBus);
      }
      connection.onDisconnected = onDisconnected;

      // Connect
      _connectTimer = MqttCancellableAsyncSleep(5000);
      await connection.connect(hostname, port);
      registerForMessage(MqttMessageType.connectAck, _connectAckProcessor);
      _clientEventBus.on<MessageAvailable>().listen(messageAvailable);
      // Transmit the required connection message to the broker.
      MqttLogger.log('SynchronousMqttConnectionHandler::internalConnect '
          'sending connect message');
      sendMessage(connectMessage);
      MqttLogger.log('SynchronousMqttConnectionHandler::internalConnect - '
          'pre sleep, state = $connectionStatus');
      // We're the sync connection handler so we need to wait for the
      // brokers acknowledgement of the connections
      await _connectTimer.sleep();
      MqttLogger.log('SynchronousMqttConnectionHandler::internalConnect - '
          'post sleep, state = $connectionStatus');
    } while (connectionStatus.state != MqttConnectionState.connected &&
        ++connectionAttempts < maxConnectionAttempts);
    // If we've failed to handshake with the broker, throw an exception.
    if (connectionStatus.state != MqttConnectionState.connected) {
      MqttLogger.log(
          'SynchronousMqttConnectionHandler::internalConnect failed');
      throw NoConnectionException('The maximum allowed connection attempts '
          '({$maxConnectionAttempts}) were exceeded. '
          'The broker is not responding to the connection request message '
          '(Missing Connection Acknowledgement');
    }
    MqttLogger.log('SynchronousMqttConnectionHandler::internalConnect '
        'exited with state $connectionStatus');
    return connectionStatus;
  }

  /// Disconnects
  @override
  MqttConnectionState disconnect() {
    MqttLogger.log('SynchronousMqttConnectionHandler::disconnect');
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
    MqttLogger.log('SynchronousMqttConnectionHandler::_connectAckProcessor');
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
        MqttLogger.log('SynchronousMqttConnectionHandler::_connectAckProcessor '
            'connection rejected');
        connectionStatus.returnCode = ackMsg.variableHeader.returnCode;
        _performConnectionDisconnect();
      } else {
        // Initialize the keepalive to start the ping based keepalive process.
        MqttLogger.log('SynchronousMqttConnectionHandler::_connectAckProcessor '
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
        'SynchronousMqttConnectionHandler:: cancelling connect timer');
    _connectTimer.cancel();
    return true;
  }
}
