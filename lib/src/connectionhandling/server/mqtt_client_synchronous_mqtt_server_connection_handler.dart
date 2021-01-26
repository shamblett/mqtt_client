/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_server_client;

/// Connection handler that performs server based connections and disconnections
/// to the hostname in a synchronous manner.
class SynchronousMqttServerConnectionHandler
    extends MqttServerConnectionHandler {
  /// Initializes a new instance of the SynchronousMqttConnectionHandler class.
  SynchronousMqttServerConnectionHandler(
    clientEventBus, {
    required int maxConnectionAttempts,
  }) : super(clientEventBus, maxConnectionAttempts: maxConnectionAttempts) {
    connectTimer = MqttCancellableAsyncSleep(5000);
    initialiseListeners();
  }

  /// Synchronously connect to the specific Mqtt Connection.
  @override
  Future<MqttClientConnectionStatus> internalConnect(
      String? hostname, int? port, MqttConnectMessage? connectMessage) async {
    var connectionAttempts = 0;
    MqttLogger.log(
        'SynchronousMqttServerConnectionHandler::internalConnect entered');
    do {
      // Initiate the connection
      MqttLogger.log(
          'SynchronousMqttServerConnectionHandler::internalConnect - '
          'initiating connection try $connectionAttempts, auto reconnect in progress $autoReconnectInProgress');
      connectionStatus.state = MqttConnectionState.connecting;
      connectionStatus.returnCode = MqttConnectReturnCode.noneSpecified;
      // Don't reallocate the connection if this is an auto reconnect
      if (!autoReconnectInProgress!) {
        if (useWebSocket) {
          if (useAlternateWebSocketImplementation) {
            MqttLogger.log(
                'SynchronousMqttServerConnectionHandler::internalConnect - '
                'alternate websocket implementation selected');
            connection =
                MqttServerWs2Connection(securityContext, clientEventBus);
          } else {
            MqttLogger.log(
                'SynchronousMqttServerConnectionHandler::internalConnect - '
                'websocket selected');
            connection = MqttServerWsConnection(clientEventBus);
          }
          if (websocketProtocols != null) {
            connection.protocols = websocketProtocols;
          }
        } else if (secure) {
          MqttLogger.log(
              'SynchronousMqttServerConnectionHandler::internalConnect - '
              'secure selected');
          connection = MqttServerSecureConnection(
              securityContext, clientEventBus, onBadCertificate);
        } else {
          MqttLogger.log(
              'SynchronousMqttServerConnectionHandler::internalConnect - '
              'insecure TCP selected');
          connection = MqttServerNormalConnection(clientEventBus);
        }
        connection.onDisconnected = onDisconnected;
      }

      // Connect
      try {
        if (!autoReconnectInProgress!) {
          MqttLogger.log(
              'SynchronousMqttServerConnectionHandler::internalConnect - calling connect');
          await connection.connect(hostname, port);
        } else {
          MqttLogger.log(
              'SynchronousMqttServerConnectionHandler::internalConnect - calling connectAuto');
          await connection.connectAuto(hostname, port);
        }
      } on Exception {
        // Ignore exceptions in an auto reconnect sequence
        if (autoReconnectInProgress!) {
          MqttLogger.log(
              'SynchronousMqttServerConnectionHandler::internalConnect'
              ' exception thrown during auto reconnect - ignoring');
        } else {
          rethrow;
        }
      }
      MqttLogger.log(
          'SynchronousMqttServerConnectionHandler::internalConnect - '
          'connection complete');
      // Transmit the required connection message to the broker.
      MqttLogger.log('SynchronousMqttServerConnectionHandler::internalConnect '
          'sending connect message');
      sendMessage(connectMessage);
      MqttLogger.log(
          'SynchronousMqttServerConnectionHandler::internalConnect - '
          'pre sleep, state = $connectionStatus');
      // We're the sync connection handler so we need to wait for the
      // brokers acknowledgement of the connections
      await connectTimer.sleep();
      MqttLogger.log(
          'SynchronousMqttServerConnectionHandler::internalConnect - '
          'post sleep, state = $connectionStatus');
    } while (connectionStatus.state != MqttConnectionState.connected &&
        ++connectionAttempts < maxConnectionAttempts!);
    // If we've failed to handshake with the broker, throw an exception.
    if (connectionStatus.state != MqttConnectionState.connected) {
      if (!autoReconnectInProgress!) {
        MqttLogger.log(
            'SynchronousMqttServerConnectionHandler::internalConnect failed');
        if (connectionStatus.returnCode ==
            MqttConnectReturnCode.noneSpecified) {
          throw NoConnectionException('The maximum allowed connection attempts '
              '({$maxConnectionAttempts}) were exceeded. '
              'The broker is not responding to the connection request message '
              '(Missing Connection Acknowledgement?');
        } else {
          throw NoConnectionException('The maximum allowed connection attempts '
              '({$maxConnectionAttempts}) were exceeded. '
              'The broker is not responding to the connection request message correctly '
              'The return code is ${connectionStatus.returnCode}');
        }
      }
    }
    MqttLogger.log('SynchronousMqttServerConnectionHandler::internalConnect '
        'exited with state $connectionStatus');
    initialConnectionComplete = true;
    return connectionStatus;
  }
}
