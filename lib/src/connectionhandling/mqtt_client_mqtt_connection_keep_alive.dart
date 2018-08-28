/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Implements keepalive functionality on the Mqtt Connection, ensuring that the connection
/// remains active according to the keepalive seconds setting.
/// This class implements the keepalive by sending an MqttPingRequest to the broker if a message
/// has not been send or received within the keepalive period.
class MqttConnectionKeepAlive {
  /// Initializes a new instance of the MqttConnectionKeepAlive class.
  MqttConnectionKeepAlive(
      IMqttConnectionHandler connectionHandler, int keepAliveSeconds) {
    this._connectionHandler = connectionHandler;
    this.keepAlivePeriod = keepAliveSeconds * 1000;
    // Register for message handling of ping request and response messages.
    connectionHandler.registerForMessage(
        MqttMessageType.pingRequest, pingRequestReceived);
    connectionHandler.registerForMessage(
        MqttMessageType.pingResponse, pingResponseReceived);
    connectionHandler.registerForAllSentMessages(messageSent);
    // Start the timer so we do a ping whenever required.
    pingTimer =
        Timer(Duration(milliseconds: this.keepAlivePeriod), pingRequired);
  }

  /// The keep alive period in  milliseconds
  int keepAlivePeriod;

  /// The timer that manages the ping callbacks.
  Timer pingTimer;

  /// The connection handler
  MqttConnectionHandler _connectionHandler;

  /// Used to synchronise shutdown and ping operations.
  bool _shutdownPadlock = false;

  /// Pings the message broker if there has been no activity for the specified amount of idle time.
  bool pingRequired() {
    if (_shutdownPadlock) {
      return false;
    } else {
      _shutdownPadlock = true;
    }
    bool pinged = false;
    final MqttPingRequestMessage pingMsg = MqttPingRequestMessage();
    if (_connectionHandler.connectionState == ConnectionState.connected) {
      _connectionHandler.sendMessage(pingMsg);
      pinged = true;
    }
    pingTimer =
        Timer(Duration(milliseconds: this.keepAlivePeriod), pingRequired);
    _shutdownPadlock = false;
    return pinged;
  }

  /// Signal to the keepalive that a ping request has been received from the message broker.
  /// The effect of calling this method on the keepalive handler is the transmission of a ping response
  /// message to the message broker on the current connection.
  bool pingRequestReceived(MqttMessage pingMsg) {
    if (_shutdownPadlock) {
      return false;
    } else {
      _shutdownPadlock = true;
    }
    final MqttPingResponseMessage pingMsg = MqttPingResponseMessage();
    _connectionHandler.sendMessage(pingMsg);
    _shutdownPadlock = false;
    return true;
  }

  /// Processed ping response messages received from a message broker.
  bool pingResponseReceived(MqttMessage pingMsg) {
    return true;
  }

  /// Handles the MessageSent event of the connectionHandler control.
  bool messageSent(MqttMessage msg) {
    return true;
  }

  /// Stop the keep alive process
  void stop() {
    pingTimer.cancel();
  }
}
