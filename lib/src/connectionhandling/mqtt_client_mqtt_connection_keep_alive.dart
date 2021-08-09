/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Ping response received callback
typedef PongCallback = void Function();

/// Implements keep alive functionality on the Mqtt Connection,
/// ensuring that the connection remains active according to the
/// keep alive seconds setting.
/// This class implements the keep alive by sending an MqttPingRequest
/// to the broker if a message has not been sent or received
/// within the keep alive period.
/// Optionally a disconnect on no response property can be set to force disconnect the client
/// if the broker does not respond to a ping request for a specified period of time.
class MqttConnectionKeepAlive {
  /// Initializes a new instance of the MqttConnectionKeepAlive class.
  MqttConnectionKeepAlive(IMqttConnectionHandler connectionHandler,
      events.EventBus? eventBus, int keepAliveSeconds,
      [int disconnectOnNoResponsePeriod = 0]) {
    _connectionHandler = connectionHandler;
    _clientEventBus = eventBus;
    this.disconnectOnNoResponsePeriod = disconnectOnNoResponsePeriod * 1000;
    keepAlivePeriod = keepAliveSeconds * 1000;
    // Register for message handling of ping request and response messages.
    connectionHandler.registerForMessage(
        MqttMessageType.pingRequest, pingRequestReceived);
    connectionHandler.registerForMessage(
        MqttMessageType.pingResponse, pingResponseReceived);
    connectionHandler.registerForAllSentMessages(messageSent);
    // Start the timer so we do a ping whenever required.
    pingTimer = Timer(Duration(milliseconds: keepAlivePeriod), pingRequired);
    MqttLogger.log(
        'MqttConnectionKeepAlive:: Initialised with a keep alive value of $keepAliveSeconds seconds');
    disconnectOnNoResponsePeriod == 0
        ? MqttLogger.log(
            'MqttConnectionKeepAlive:: Disconnect on no ping response is disabled')
        : MqttLogger.log(
            'MqttConnectionKeepAlive:: Disconnect on no ping response is enabled with a value of $disconnectOnNoResponsePeriod seconds');
  }

  /// The keep alive period in  milliseconds
  late int keepAlivePeriod;

  /// The period of time to wait if the broker does not respond to a ping request, in milliseconds.
  /// If this time period is exceeded the client is forcibly disconnected.
  /// The default is 0, which disables this functionality.
  int disconnectOnNoResponsePeriod = 0;

  /// The timer that manages the ping callbacks.
  Timer? pingTimer;

  /// Timer that manages the disconnect on no ping response period.
  Timer? disconnectTimer;

  /// The connection handler
  late IMqttConnectionHandler _connectionHandler;

  /// Used to synchronise shutdown and ping operations.
  bool _shutdownPadlock = false;

  /// Ping response received callback
  PongCallback? pongCallback;

  /// The event bus
  events.EventBus? _clientEventBus;

  /// Pings the message broker if there has been no activity for
  /// the specified amount of idle time.
  bool pingRequired() {
    MqttLogger.log('MqttConnectionKeepAlive::pingRequired');
    if (_shutdownPadlock) {
      return false;
    } else {
      _shutdownPadlock = true;
    }
    var pinged = false;
    final pingMsg = MqttPingRequestMessage();
    if (_connectionHandler.connectionStatus.state ==
        MqttConnectionState.connected) {
      MqttLogger.log(
          'MqttConnectionKeepAlive::pingRequired - sending ping request');
      _connectionHandler.sendMessage(pingMsg);
      pinged = true;
    } else {
      MqttLogger.log(
          'MqttConnectionKeepAlive::pingRequired - NOT sending ping - not connected');
    }
    MqttLogger.log(
        'MqttConnectionKeepAlive::pingRequired - restarting ping timer');
    pingTimer = Timer(Duration(milliseconds: keepAlivePeriod), pingRequired);
    if (disconnectOnNoResponsePeriod != 0) {
      if (disconnectTimer == null) {
        MqttLogger.log(
            'MqttConnectionKeepAlive::pingRequired - starting disconnect timer');
        if (pinged) {
          disconnectTimer = Timer(
              Duration(milliseconds: disconnectOnNoResponsePeriod),
              noPingResponseReceived);
        }
      } else {
        if (disconnectTimer != null && !disconnectTimer!.isActive) {
          if (pinged) {
            MqttLogger.log(
                'MqttConnectionKeepAlive::pingRequired - restarting disconnect timer');
            disconnectTimer = Timer(
                Duration(milliseconds: disconnectOnNoResponsePeriod),
                noPingResponseReceived);
          }
        } else {
          MqttLogger.log(
              'MqttConnectionKeepAlive::pingRequired - disconnect timer is active, not restarting');
        }
      }
    }
    _shutdownPadlock = false;
    return pinged;
  }

  /// A ping request has been received from the message broker.
  /// The effect of calling this method on the keep alive handler is the
  /// transmission of a ping response message to the message broker on
  /// the current connection.
  bool pingRequestReceived(MqttMessage? pingMsg) {
    MqttLogger.log('MqttConnectionKeepAlive::pingRequestReceived');
    if (_shutdownPadlock) {
      return false;
    } else {
      _shutdownPadlock = true;
    }
    final pingMsg = MqttPingResponseMessage();
    _connectionHandler.sendMessage(pingMsg);
    _shutdownPadlock = false;
    return true;
  }

  /// Processed ping response messages received from a message broker.
  bool pingResponseReceived(MqttMessage? pingMsg) {
    MqttLogger.log('MqttConnectionKeepAlive::pingResponseReceived');
    // Call the pong callback if not null
    if (pongCallback != null) {
      pongCallback!();
    }
    // Cancel the disconnect timer if needed.
    disconnectTimer?.cancel();
    return true;
  }

  /// Handles the MessageSent event of the connectionHandler control.
  bool messageSent(MqttMessage? msg) => true;

  /// Stop the keep alive process
  void stop() {
    MqttLogger.log('MqttConnectionKeepAlive::stop - stopping keep alive');
    pingTimer!.cancel();
    disconnectTimer?.cancel();
  }

  /// Handle the disconnect timer timeout
  void noPingResponseReceived() {
    // Only disconnect if we are connected.
    if (_connectionHandler.connectionStatus.state ==
        MqttConnectionState.connected) {
      MqttLogger.log(
          'MqttConnectionKeepAlive::noPingResponseReceived - connected, attempting to disconnect');
      if (_clientEventBus != null) {
        _clientEventBus!.fire(DisconnectOnNoPingResponse());
        MqttLogger.log(
            'MqttConnectionKeepAlive::noPingResponseReceived - OK - disconnect event fired');
      } else {
        MqttLogger.log(
            'MqttConnectionKeepAlive::noPingResponseReceived - ERROR - disconnect event not fired, no event handler');
      }
    } else {
      MqttLogger.log(
          'MqttConnectionKeepAlive::noPingResponseReceived - not disconnecting, not connected');
    }
  }
}
