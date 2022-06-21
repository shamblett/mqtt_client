/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_browser_client;

/// The MQTT browser connection base class
abstract class MqttBrowserConnection<T extends Object>
    extends MqttConnectionBase<T> {
  /// Default constructor
  MqttBrowserConnection(clientEventBus) : super(clientEventBus);

  /// Initializes a new instance of the MqttBrowserConnection class.
  MqttBrowserConnection.fromConnect(server, port, clientEventBus)
      : super(clientEventBus) {
    connect(server, port);
  }

  /// Create the listening stream subscription and subscribe the callbacks
  void _startListening() {
    stopListening();
    MqttLogger.log('MqttBrowserConnection::_startListening');
    try {
      onListen();
    } on Exception catch (e) {
      MqttLogger.log(
          'MqttBrowserConnection::_startListening - exception raised $e');
    }
  }

  /// Implement stream subscription
  List<StreamSubscription> onListen();

  /// OnData listener callback
  void onData(dynamic /*String|List<int>*/ byteData) {
    MqttLogger.log('MqttBrowserConnection::_onData');
    // Protect against 0 bytes but should never happen.
    var data = Uint8List.view(byteData);
    if (data.isEmpty) {
      MqttLogger.log('MqttBrowserConnection::_ondata - Error - 0 byte message');
      return;
    }

    messageStream.addAll(data);

    while (messageStream.isMessageAvailable()) {
      var messageIsValid = true;
      MqttMessage? msg;

      try {
        msg = MqttMessage.createFrom(messageStream);
      } on Exception {
        MqttLogger.log(
            'MqttBrowserConnection::_ondata - message is not yet valid, '
            'waiting for more data ...');
        messageIsValid = false;
      }
      if (!messageIsValid) {
        messageStream.reset();
        return;
      }
      if (messageIsValid) {
        messageStream.shrink();
        MqttLogger.log(
            'MqttBrowserConnection::_onData - message received ', msg);
        if (!clientEventBus!.streamController.isClosed) {
          if (msg!.header!.messageType == MqttMessageType.connectAck) {
            clientEventBus!.fire(ConnectAckMessageAvailable(msg));
          } else {
            clientEventBus!.fire(MessageAvailable(msg));
          }
          MqttLogger.log(
              'MqttBrowserConnection::_onData - message available event fired');
        } else {
          MqttLogger.log(
              'MqttBrowserConnection::_onData - WARN - message available event not fired, event bus is closed');
        }
      }
    }
  }
}
