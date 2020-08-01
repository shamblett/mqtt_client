/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_server_client;

/// The MQTT client server connection base class
class MqttServerConnection extends MqttConnectionBase {
  /// Default constructor
  MqttServerConnection(clientEventBus) : super(clientEventBus);

  /// Initializes a new instance of the MqttConnection class.
  MqttServerConnection.fromConnect(server, port, clientEventBus)
      : super(clientEventBus) {
    connect(server, port);
  }

  /// Connect, must be overridden in connection classes
  @override
  Future<void> connect(String server, int port) {
    final completer = Completer<void>();
    return completer.future;
  }

  /// Create the listening stream subscription and subscribe the callbacks
  void _startListening() {
    MqttLogger.log('MqttServerConnection::_startListening');
    try {
      client.listen(_onData, onError: onError, onDone: onDone);
    } on Exception catch (e) {
      print('MqttServerConnection::_startListening - exception raised $e');
    }
  }

  /// OnData listener callback
  void _onData(dynamic data) {
    MqttLogger.log('MqttConnection::_onData');
    // Protect against 0 bytes but should never happen.
    if (data.length == 0) {
      MqttLogger.log('MqttServerConnection::_ondata - Error - 0 byte message');
      return;
    }

    messageStream.addAll(data);

    while (messageStream.isMessageAvailable()) {
      var messageIsValid = true;
      MqttMessage msg;

      try {
        msg = MqttMessage.createFrom(messageStream);
        if (msg == null) {
          return;
        }
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
        MqttLogger.log('MqttServerConnection::_onData - message received $msg');
        if (!clientEventBus.streamController.isClosed) {
          clientEventBus.fire(MessageAvailable(msg));
          MqttLogger.log('MqttServerConnection::_onData - message processed');
        } else {
          MqttLogger.log(
              'MqttServerConnection::_onData - message not processed, disconnecting');
        }
      }
    }
  }

  /// Sends the message in the stream to the broker.
  void send(MqttByteBuffer message) {
    final messageBytes = message.read(message.length);
    client?.add(messageBytes.toList());
  }
}
