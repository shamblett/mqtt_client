/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// State and logic used to read from the underlying network stream.
class ReadWrapper {
  /// Creates a new ReadWrapper that wraps the state used to read a message from a stream.
  ReadWrapper() {
    messageBytes = List<int>();
  }

  /// The bytes associated with the message being read.
  List<int> messageBytes;
}

/// The MQTT connection base class
class MqttConnection {
  /// Default constructor
  MqttConnection(this._clientEventBus);

  /// Initializes a new instance of the MqttConnection class.
  MqttConnection.fromConnect(String server, int port, this._clientEventBus) {
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
  events.EventBus _clientEventBus;

  /// Connect, must be overridden in connection classes
  Future<void> connect(String server, int port) {
    final Completer<void> completer = Completer<void>();
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
      bool messageIsValid = true;
      MqttMessage msg;

      try {
        msg = MqttMessage.createFrom(messageStream);
        if (msg == null) {
          return;
        }
      } on Exception catch (e) {
        MqttLogger.log('MqttConnection::_ondata - message is not valid');
        MqttLogger.log('MqttConnection::_ondata - exception is $e');
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
    onDisconnected();
  }

  /// OnDone listener callback
  void _onDone() {
    _disconnect();
    MqttLogger.log('MqttConnection::_onDone - calling disconnected callback');
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
    final typed.Uint8Buffer messageBytes = message.read(message.length);
    client?.add(messageBytes.toList());
  }

  /// User requested disconnection
  void disconnect() {
    _onDone();
  }
}
