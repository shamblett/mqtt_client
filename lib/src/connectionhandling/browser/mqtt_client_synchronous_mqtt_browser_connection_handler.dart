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
  SynchronousMqttBrowserConnectionHandler(
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
        'SynchronousMqttBrowserConnectionHandler::internalConnect entered');
    do {
      // Initiate the connection
      MqttLogger.log(
          'SynchronousMqttBrowserConnectionHandler::internalConnect - '
          'initiating connection try $connectionAttempts, auto reconnect in progress $autoReconnectInProgress');
      connectionStatus.state = MqttConnectionState.connecting;
      connectionStatus.returnCode = MqttConnectReturnCode.noneSpecified;
      // Don't reallocate the connection if this is an auto reconnect
      if (!autoReconnectInProgress!) {
        connection = MqttBrowserWsConnection(clientEventBus);
        if (websocketProtocols != null) {
          connection.protocols = websocketProtocols;
        }
        connection.onDisconnected = onDisconnected;
      }
      // Connect
      try {
        if (!autoReconnectInProgress!) {
          MqttLogger.log(
              'SynchronousMqttBrowserConnectionHandler::internalConnect - calling connect');
          await connection.connect(hostname, port);
        } else {
          MqttLogger.log(
              'SynchronousMqttBrowserConnectionHandler::internalConnect - calling connectAuto');
          await connection.connectAuto(hostname, port);
        }
      } on Exception {
        // Ignore exceptions in an auto reconnect sequence
        if (autoReconnectInProgress!) {
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
        ++connectionAttempts < maxConnectionAttempts!);
    // If we've failed to handshake with the broker, throw an exception.
    if (connectionStatus.state != MqttConnectionState.connected) {
      if (!autoReconnectInProgress!) {
        MqttLogger.log(
            'SynchronousMqttBrowserConnectionHandler::internalConnect failed');
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
    MqttLogger.log('SynchronousMqttBrowserConnectionHandler::internalConnect '
        'exited with state $connectionStatus');
    initialConnectionComplete = true;
    return connectionStatus;
  }
}
