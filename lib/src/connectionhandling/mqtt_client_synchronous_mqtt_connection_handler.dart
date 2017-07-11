/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Connection handler that performs connections and disconnections to the hostname in a synchronous manner.
class SynchronousMqttConnectionHandler extends MqttConnectionHandler
    with events.EventDetector {
  static const int maxConnectionAttempts = 3;

  /// Synchronously connect to the specific Mqtt Connection.
  Future<ConnectionState> internalConnect(String hostname, int port,
      MqttConnectMessage connectMessage) async {
    int connectionAttempts = 0;
    MqttLogger.log("SynchronousMqttConnectionHandler::internalConnect entered");
    do {
      // Initiate the connection
      MqttLogger.log(
          "SynchronousMqttConnectionHandler::internalConnect - initiating connection try $connectionAttempts");
      connectionState = ConnectionState.connecting;
      connection = new MqttConnection();
      await connection.connect(hostname, port);
      this.registerForMessage(MqttMessageType.connectAck, _connectAckProcessor);
      this.listen(connection, MessageAvailable, this.messageAvailable);
      // Transmit the required connection message to the broker.
      MqttLogger.log(
          "SynchronousMqttConnectionHandler::internalConnect sending connect message");
      sendMessage(connectMessage);
      MqttLogger.log(
          "SynchronousMqttConnectionHandler::internalConnect - pre sleep, state = $connectionState");
      // We're the sync connection handler so we need to wait for the brokers acknowledgement of the connections
      await MqttUtilities.asyncSleep(5);
      MqttLogger.log(
          "SynchronousMqttConnectionHandler::internalConnect - post sleep, state = $connectionState");
    } while (connectionState != ConnectionState.connected &&
        ++connectionAttempts < maxConnectionAttempts);
    // If we've failed to handshake with the broker, throw an exception.
    if (connectionState != ConnectionState.connected) {
      MqttLogger
          .log("SynchronousMqttConnectionHandler::internalConnect failed");
      throw new NoConnectionException(
          "The maximum allowed connection attempts ({$maxConnectionAttempts}) were exceeded. "
              "The broker is not responding to the connection request message "
              "(Missing Connection Acknowledgement");
    }
    return connectionState;
  }

  ConnectionState disconnect() {
    MqttLogger.log("SynchronousMqttConnectionHandler::disconnect");
    // Send a disconnect message to the broker
    connectionState = ConnectionState.disconnecting;
    sendMessage(new MqttDisconnectMessage());
    this.ignoreAllEvents();
    _performConnectionDisconnect();
    return connectionState = ConnectionState.disconnected;
  }

  /// Disconnects the underlying connection object.
  void _performConnectionDisconnect() {
    // set the connection to disconnected.
    connectionState = ConnectionState.disconnecting;
    connection = null;
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
