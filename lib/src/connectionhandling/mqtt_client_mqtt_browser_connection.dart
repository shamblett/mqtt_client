/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_browser_client;

/// The MQTT browser connection base class
class MqttBrowserConnection {
  /// Default constructor
  MqttBrowserConnection(this._clientEventBus);

  /// Initializes a new instance of the MqttBrowserConnection class.
  MqttBrowserConnection.fromConnect(
      String server, int port, this._clientEventBus) {
    connect(server, port);
  }

  /// The web socket that maintains the connection to the MQTT broker.
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
    MqttLogger.log('MqttBrowserConnection::_startListening');
    try {
      client.onClose.listen((e) {
        MqttLogger.log(
            'MqttBrowserConnection::_startListening - websocket is closed');
        _onDone();
      });
      client.onMessage.listen((MessageEvent e) {
        _onData(e.data);
      });
      client.onError.listen((e) {
        _onError(e);
      });
    } on Exception catch (e) {
      MqttLogger.log(
          'MqttBrowserConnection::_startListening - exception raised $e');
    }
  }

  /// OnData listener callback
  void _onData(dynamic byteData) {
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
      MqttMessage msg;

      try {
        msg = MqttMessage.createFrom(messageStream);
        if (msg == null) {
          return;
        }
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
            'MqttBrowserConnection::_onData - message received $msg');
        if (!_clientEventBus.streamController.isClosed) {
          _clientEventBus.fire(MessageAvailable(msg));
          MqttLogger.log('MqttBrowserConnection::_onData - message processed');
        } else {
          MqttLogger.log(
              'MqttBrowserConnection::_onData - message not processed, disconnecting');
        }
      }
    }
  }

  /// OnError listener callback
  void _onError(dynamic error) {
    _disconnect();
    if (onDisconnected != null) {
      MqttLogger.log(
          'MqttBrowserConnection::_onError - calling disconnected callback');
      onDisconnected();
    }
  }

  /// OnDone listener callback
  void _onDone() {
    _disconnect();
    MqttLogger.log(
        'MqttBrowserConnection::_onDone - calling disconnected callback');
    onDisconnected();
  }

  /// Disconnects from the message broker
  void _disconnect() {
    if (client != null) {
      client.close();
      client = null;
    }
  }

  /// Sends the message in the stream to the broker.
  void send(MqttByteBuffer message) {
    final messageBytes = message.read(message.length);
    var buffer = messageBytes.buffer;
    var bdata = ByteData.view(buffer);
    client?.sendTypedData(bdata);
  }

  /// User requested disconnection
  void disconnect() {
    _onDone();
  }
}
