/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Connection handler that performs connections and disconnections to the hostname in a synchronous manner.
class SynchronousMqttConnectionHandler extends MqttConnectionHandler {
  /// Max connection attempts
  static const int maxConnectionAttempts = 3;

  /// The broker connection acknowledgment timer
  MqttCancellableAsyncSleep _connectTimer;

  /// The event bus
  events.EventBus _clientEventBus;

  /// Initializes a new instance of the MqttConnectionHandler class.
  SynchronousMqttConnectionHandler(this._clientEventBus);

  /// Synchronously connect to the specific Mqtt Connection.
  Future internalConnect(
      String hostname, int port, MqttConnectMessage connectMessage) async {
    int connectionAttempts = 0;
    MqttLogger.log("SynchronousMqttConnectionHandler::internalConnect entered");
    do {
      // Initiate the connection
      MqttLogger.log(
          "SynchronousMqttConnectionHandler::internalConnect - initiating connection try $connectionAttempts");
      connectionState.state = ConnectionState.connecting;
      if (useWebSocket) {
        MqttLogger.log(
            "SynchronousMqttConnectionHandler::internalConnect - websocket selected");
        connection = MqttWsConnection(_clientEventBus);
      } else if (secure) {
        MqttLogger.log(
            "SynchronousMqttConnectionHandler::internalConnect - secure selected");
        connection = MqttSecureConnection(trustedCertPath, privateKeyFilePath,
            certificateChainPath, privateKeyFilePassphrase, _clientEventBus);
      } else {
        MqttLogger.log(
            "SynchronousMqttConnectionHandler::internalConnect - insecure TCP selected");
        connection = MqttNormalConnection(_clientEventBus);
      }
      connection.onDisconnected = onDisconnected;

      // Connect
      _connectTimer = new MqttCancellableAsyncSleep(5000);
      await connection.connect(hostname, port);
      this.registerForMessage(MqttMessageType.connectAck, _connectAckProcessor);
      _clientEventBus.on<MessageAvailable>().listen(this.messageAvailable);
      // Transmit the required connection message to the broker.
      MqttLogger.log(
          "SynchronousMqttConnectionHandler::internalConnect sending connect message");
      sendMessage(connectMessage);
      MqttLogger.log(
          "SynchronousMqttConnectionHandler::internalConnect - pre sleep, state = $connectionState");
      // We're the sync connection handler so we need to wait for the brokers acknowledgement of the connections
      await _connectTimer.sleep();
      MqttLogger.log(
          "SynchronousMqttConnectionHandler::internalConnect - post sleep, state = $connectionState");
    } while (connectionState.state != ConnectionState.connected &&
        ++connectionAttempts < maxConnectionAttempts);
    // If we've failed to handshake with the broker, throw an exception.
    if (connectionState.state != ConnectionState.connected) {
      MqttLogger.log(
          "SynchronousMqttConnectionHandler::internalConnect failed");
      throw NoConnectionException(
          "The maximum allowed connection attempts ({$maxConnectionAttempts}) were exceeded. "
          "The broker is not responding to the connection request message "
          "(Missing Connection Acknowledgement");
    }
    MqttLogger.log(
        "SynchronousMqttConnectionHandler::internalConnect exited with state $connectionState");
    return connectionState;
  }

  ConnectionState disconnect() {
    MqttLogger.log("SynchronousMqttConnectionHandler::disconnect");
    // Send a disconnect message to the broker
    connectionState.state = ConnectionState.disconnecting;
    sendMessage(MqttDisconnectMessage());
    _performConnectionDisconnect();
    return connectionState.state = ConnectionState.disconnected;
  }

  /// Disconnects the underlying connection object.
  void _performConnectionDisconnect() {
    // Set the connection to disconnected.
    connection?.disconnectRequested = true;
    connectionState.state = ConnectionState.disconnected;
  }

  /// Processes the connect acknowledgement message.
  bool _connectAckProcessor(MqttMessage msg) {
    MqttLogger.log("SynchronousMqttConnectionHandler::_connectAckProcessor");
    try {
      final MqttConnectAckMessage ackMsg = msg as MqttConnectAckMessage;
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
            "SynchronousMqttConnectionHandler::_connectAckProcessor connection rejected");
        connectionState.returnCode = ackMsg.variableHeader.returnCode;
        _performConnectionDisconnect();
      } else {
        // Initialize the keepalive to start the ping based keepalive process.
        MqttLogger.log(
            "SynchronousMqttConnectionHandler::_connectAckProcessor - state = connected");
        connectionState.state = ConnectionState.connected;
        connectionState.returnCode = MqttConnectReturnCode.connectionAccepted;
      }
    } catch (InvalidMessageException) {
      _performConnectionDisconnect();
    }
    // Cancel the connect timer;
    MqttLogger.log(
        "SynchronousMqttConnectionHandler:: cancelling connect timer");
    _connectTimer.cancel();
    return true;
  }
}
