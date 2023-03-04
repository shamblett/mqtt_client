/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_server_client;

/// The MQTT client server connection base class
abstract class MqttServerConnection<T extends Object>
    extends MqttConnectionBase<T> {
  /// Default constructor
  MqttServerConnection(clientEventBus, this.socketOptions)
      : super(clientEventBus);

  /// Initializes a new instance of the MqttConnection class.
  MqttServerConnection.fromConnect(
      server, port, clientEventBus, this.socketOptions)
      : super(clientEventBus) {
    connect(server, port);
  }

  /// Socket options, applicable only to TCP sockets
  List<RawSocketOption> socketOptions = <RawSocketOption>[];

  /// Create the listening stream subscription and subscribe the callbacks
  void _startListening() {
    stopListening();
    MqttLogger.log('MqttServerConnection::_startListening');
    try {
      listeners.add(onListen());
    } on Exception catch (e) {
      print('MqttServerConnection::_startListening - exception raised $e');
    }
  }

  /// Implement stream subscription
  StreamSubscription onListen();

  /// OnData listener callback
  @protected
  void onData(dynamic /*String|List<int>*/ data) {
    MqttLogger.log('MqttConnection::onData');
    // Protect against 0 bytes but should never happen.
    if (data.length == 0) {
      MqttLogger.log('MqttServerConnection::onData - Error - 0 byte message');
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
            'MqttServerConnection::_ondata - message is not yet valid, '
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
            'MqttServerConnection::_onData - message received ', msg);
        if (!clientEventBus!.streamController.isClosed) {
          if (msg!.header!.messageType == MqttMessageType.connectAck) {
            clientEventBus!.fire(ConnectAckMessageAvailable(msg));
          } else {
            clientEventBus!.fire(MessageAvailable(msg));
          }
          MqttLogger.log(
              'MqttServerConnection::_onData - message available event fired');
        } else {
          MqttLogger.log(
              'MqttServerConnection::_onData - WARN - message available event not fired, event bus is closed');
        }
      }
    }
  }
}
