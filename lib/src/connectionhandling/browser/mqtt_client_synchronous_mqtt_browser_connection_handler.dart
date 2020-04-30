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
  SynchronousMqttBrowserConnectionHandler(clientEventBus) {
    this.clientEventBus = clientEventBus;
    clientEventBus.on<AutoReconnect>().listen(autoReconnect);
    registerForMessage(MqttMessageType.connectAck, connectAckProcessor);
    clientEventBus.on<MessageAvailable>().listen(messageAvailable);
  }

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
      connection = MqttBrowserWsConnection(clientEventBus);
      connection.onDisconnected = onDisconnected;
      if (websocketProtocols != null) {
        connection.protocols = websocketProtocols;
      }

      // Connect
      connectTimer = MqttCancellableAsyncSleep(5000);
      try {
        await connection.connect(hostname, port);
      } on Exception {
        // Ignore exceptions in an auto reconnect sequence
        if (autoReconnectInProgress) {
          MqttLogger.log(
              'SynchronousMqttBrowserConnectionHandler::internalConnect'
              ' exception thrown during auto reconnect - ignoring');
        } else {
          rethrow;
        }
      }
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
      await connectTimer.sleep();
      MqttLogger.log(
          'SynchronousMqttBrowserConnectionHandler::internalConnect - '
          'post sleep, state = $connectionStatus');
    } while (connectionStatus.state != MqttConnectionState.connected &&
        ++connectionAttempts < MqttConnectionHandlerBase.maxConnectionAttempts);
    // If we've failed to handshake with the broker, throw an exception.
    if (connectionStatus.state != MqttConnectionState.connected) {
      if (!autoReconnectInProgress) {
        MqttLogger.log(
            'SynchronousMqttBrowserConnectionHandler::internalConnect failed');
        if (connectionStatus.returnCode ==
            MqttConnectReturnCode.noneSpecified) {
          throw NoConnectionException('The maximum allowed connection attempts '
              '({$MqttConnectionHandlerBase.maxConnectionAttempts}) were exceeded. '
              'The broker is not responding to the connection request message '
              '(Missing Connection Acknowledgement?');
        } else {
          throw NoConnectionException('The maximum allowed connection attempts '
              '({$MqttConnectionHandlerBase.maxConnectionAttempts}) were exceeded. '
              'The broker is not responding to the connection request message correctly'
              'The return code is ${connectionStatus.returnCode}');
        }
      }
    }
    MqttLogger.log('SynchronousMqttBrowserConnectionHandler::internalConnect '
        'exited with state $connectionStatus');
    return connectionStatus;
  }
}
