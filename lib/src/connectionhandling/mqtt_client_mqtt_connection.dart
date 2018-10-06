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
    this.messageBytes = List<int>();
  }

  /// The bytes associated with the message being read.
  List<int> messageBytes;
}

/// The MQTT connection base class
class MqttConnection {
  /// The socket that maintains the connection to the MQTT broker.
  dynamic client;

  /// The read wrapper
  ReadWrapper readWrapper;

  ///The read buffer
  MqttByteBuffer messageStream;

  /// Indicates if disconnect(onDone) has been requested or not
  bool disconnectRequested = false;

  /// Unsolicited disconnection callback
  DisconnectCallback onDisconnected;

  /// Default constructor
  MqttConnection();

  /// Initializes a new instance of the MqttConnection class.
  MqttConnection.fromConnect(String server, int port) {
    connect(server, port);
  }

  /// Connect, must be overridden in connection classes
  Future connect(String server, int port) {
    final Completer completer = Completer();
    return completer.future;
  }

  /// Create the listening stream subscription and subscribe the callbacks
  void _startListening() {
    MqttLogger.log("MqttConnection::_startListening");
    try {
      client.listen(_onData, onError: _onError, onDone: _onDone);
    } catch (e) {
      print("MqttConnection::_startListening - exception raised ${e}");
    }
  }

  /// OnData listener callback
  void _onData(dynamic data) {
    MqttLogger.log("MqttConnection::_onData");
    // Protect against 0 bytes but should never happen.
    if (data.length == 0) {
      return;
    }
    //readWrapper.messageBytes.addAll(data);
    // Attempt to create a message, if this works we have a full message
    // if not add the bytes to the read wrapper and wait for more bytes.

    messageStream.addAll(data);

    while (messageStream.isMessageAvailable()) {
      bool messageIsValid = true;
      MqttMessage msg;

      try {
        //final MqttByteBuffer messageStream = MqttByteBuffer.fromList(data);
        msg = MqttMessage.createFrom(messageStream);
        if (msg == null) return;
      } catch (exception) {
        MqttLogger.log("MqttConnection::_ondata - message is not valid");
        messageIsValid = false;
      }
      if (!messageIsValid) return;
      if (messageIsValid) {
        messageStream.shrink();
        MqttLogger.log("MqttConnection::_onData - message received $msg");
        clientEventBus.fire(MessageAvailable(msg));
        MqttLogger.log("MqttConnection::_onData - message processed");
      }
    }
  }

  /// OnError listener callback
  void _onError(error) {
    _disconnect();
  }

  /// OnDone listener callback
  void _onDone() {
    // We should never be done unless requested
    _disconnect();
    if (!disconnectRequested) {
      if (onDisconnected != null) {
        MqttLogger.log(
            "MqttConnection::_onDone - calling disconnected callback");
        onDisconnected();
      }
    }
  }

  /// Disconnects from the message broker
  void _disconnect() {
    if (client != null) {
      client.close();
    }
  }

  /// Sends the message in the stream to the broker.
  void send(MqttByteBuffer message) {
    final typed.Uint8Buffer messageBytes = message.read(message.length);
    client.add(messageBytes.toList());
  }

  // User requested disconnection
  void disconnect() {
    disconnectRequested = true;
    _onDone();
  }
}
