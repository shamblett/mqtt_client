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

  /// Synchronously connect to the specific Mqtt Connection.
  Future internalConnect(
      String hostname, int port, MqttConnectMessage connectMessage) async {
    int connectionAttempts = 0;
    MqttLogger.log("SynchronousMqttConnectionHandler::internalConnect entered");
    do {
      // Initiate the connection
      MqttLogger.log(
          "SynchronousMqttConnectionHandler::internalConnect - initiating connection try $connectionAttempts");
      connectionState = ConnectionState.connecting;
      if (useWebSocket) {
        MqttLogger.log(
            "SynchronousMqttConnectionHandler::internalConnect - websocket selected");
        connection = MqttWsConnection();
      } else if (secure) {
        MqttLogger.log(
            "SynchronousMqttConnectionHandler::internalConnect - secure selected");
        connection = MqttSecureConnection(trustedCertPath, privateKeyFilePath,
            certificateChainPath, privateKeyFilePassphrase);
      } else {
        MqttLogger.log(
            "SynchronousMqttConnectionHandler::internalConnect - insecure TCP selected");
        connection = MqttNormalConnection();
      }
      connection.onDisconnected = onDisconnected;

      // Connect
      await connection.connect(hostname, port);
      this.registerForMessage(MqttMessageType.connectAck, _connectAckProcessor);
      clientEventBus.on<MessageAvailable>().listen(this.messageAvailable);
      // Transmit the required connection message to the broker.
      MqttLogger.log(
          "SynchronousMqttConnectionHandler::internalConnect sending connect message");
      sendMessage(connectMessage);
      MqttLogger.log(
          "SynchronousMqttConnectionHandler::internalConnect - pre sleep, state = $connectionState");
      // We're the sync connection handler so we need to wait for the brokers acknowledgement of the connections
      // Sleep for 1 millisecond to give a local server a chance to respond
      await Future.delayed(Duration(milliseconds: 1));

      if (connectionState != ConnectionState.connected) {
        int sleepCycles = 0;
        final int sleepMilliseconds = 10;
        final int maxSleepCycles = 500;
        do {
          await Future.delayed(Duration(milliseconds: sleepMilliseconds));
        } while (connectionState != ConnectionState.connected &&
            ++sleepCycles < maxSleepCycles);

        MqttLogger.log(
            "SynchronousMqttConnectionHandler::internalConnect - slept for for ${(sleepCycles +
                1) * sleepMilliseconds}ms, state = $connectionState");
      }
      MqttLogger.log(
          "SynchronousMqttConnectionHandler::internalConnect - post sleep, state = $connectionState");
    } while (connectionState != ConnectionState.connected &&
        ++connectionAttempts < maxConnectionAttempts);
    // If we've failed to handshake with the broker, throw an exception.
    if (connectionState != ConnectionState.connected) {
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
    connectionState = ConnectionState.disconnecting;
    sendMessage(MqttDisconnectMessage());
    _performConnectionDisconnect();
    return connectionState = ConnectionState.disconnected;
  }

  /// Disconnects the underlying connection object.
  void _performConnectionDisconnect() {
    // Set the connection to disconnected.
    connection?.disconnectRequested = true;
    connectionState = ConnectionState.disconnected;
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
        _performConnectionDisconnect();
      } else {
        // Initialize the keepalive to start the ping based keepalive process.
        MqttLogger.log(
            "SynchronousMqttConnectionHandler::_connectAckProcessor - state = connected");
        connectionState = ConnectionState.connected;
      }
    } catch (InvalidMessageException) {
      _performConnectionDisconnect();
    }
    return true;
  }
}
