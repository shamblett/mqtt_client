/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_server_client;

/// The MQTT client server connection base class
class MqttServerConnection {
  /// Default constructor
  MqttServerConnection(this._clientEventBus);

  /// Initializes a new instance of the MqttConnection class.
  MqttServerConnection.fromConnect(
      String server, int port, this._clientEventBus) {
    connect(server, port);
  }

  /// The socket that maintains the connection to the MQTT broker.
  dynamic client;

  /// The read wrapper
  ReadWrapper readWrapper;

  ///The read buffer
  MqttByteBuffer messageStream;

  /// Unsolicited disconnection callback
  DisconnectCallback onDisconnected;

  /// The event bus
  final events.EventBus _clientEventBus;

  /// Connect, must be overridden in connection classes
  Future<void> connect(String server, int port) {
    final completer = Completer<void>();
    return completer.future;
  }

  /// Create the listening stream subscription and subscribe the callbacks
  void _startListening() {
    MqttLogger.log('MqttConnection::_startListening');
    try {
      client.listen(_onData, onError: _onError, onDone: _onDone);
    } on Exception catch (e) {
      print('MqttConnection::_startListening - exception raised $e');
    }
  }

  /// OnData listener callback
  void _onData(dynamic data) {
    MqttLogger.log('MqttConnection::_onData');
    // Protect against 0 bytes but should never happen.
    if (data.length == 0) {
      MqttLogger.log('MqttConnection::_ondata - Error - 0 byte message');
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
        MqttLogger.log('MqttConnection::_ondata - message is not yet valid, '
            'waiting for more data ...');
        messageIsValid = false;
      }
      if (!messageIsValid) {
        messageStream.reset();
        return;
      }
      if (messageIsValid) {
        messageStream.shrink();
        MqttLogger.log('MqttConnection::_onData - message received $msg');
        if (!_clientEventBus.streamController.isClosed) {
          _clientEventBus.fire(MessageAvailable(msg));
          MqttLogger.log('MqttConnection::_onData - message processed');
        } else {
          MqttLogger.log(
              'MqttConnection::_onData - message not processed, disconnecting');
        }
      }
    }
  }

  /// OnError listener callback
  void _onError(dynamic error) {
    _disconnect();
    MqttLogger.log('MqttConnection::_onError - calling disconnected callback');
    if (onDisconnected != null) {
      onDisconnected();
    }
  }

  /// OnDone listener callback
  void _onDone() {
    _disconnect();
    MqttLogger.log('MqttConnection::_onDone - calling disconnected callback');
    if (onDisconnected != null) {
      onDisconnected();
    }
  }

  void _disconnect() {
    if (client != null) {
      client.close();
      client = null;
    }
  }

  /// Sends the message in the stream to the broker.
  void send(MqttByteBuffer message) {
    final messageBytes = message.read(message.length);
    client?.add(messageBytes.toList());
  }

  /// User requested or auto disconnect disconnection
  void disconnect({bool auto = false}) {
    if (auto) {
      _disconnect();
    } else {
      _onDone();
    }
  }
}
