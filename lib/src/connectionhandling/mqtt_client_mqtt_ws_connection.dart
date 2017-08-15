/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/08/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// The MQTT connection class for the websocket interface
class MqttWsConnection extends Object with events.EventEmitter {
  /// The socket that maintains the connection to the MQTT broker.
  WebSocket wsClient;

  /// Sync lock object to ensure that only a single message is sent through the connection handler at once.
  bool _sendPadlock = false;

  /// The read wrapper
  ReadWrapper readWrapper;

  /// Indicates if disconnect(onDone) has been requested or not
  bool disconnectRequested = false;

  /// Default constructor
  MqttWsConnection();

  /// Initializes a new instance of the MqttConnection class.
  MqttWsConnection.fromConnect(String server, int port) {
    connect(server, port);
  }

  /// Connect
  Future connect(String server, int port) {
    final Completer completer = new Completer();
    // Add the port if present
    Uri uri;
    try {
      uri = Uri.parse(server);
    } catch (FormatException) {
      final String message =
          "MqttConnection::The URI supplied for the WS connection is not valid - $server";
      throw new NoConnectionException(message);
    }
    if (port != null) {
      uri = uri.replace(port: port);
    }
    final String uriString = uri.toString();
    try {
      // Connect and save the socket.
      WebSocket.connect(uriString).then((socket) {
        wsClient = socket;
        readWrapper = new ReadWrapper();
        _startListening();
        return completer.complete();
      }).catchError((e) => _onError(e));
    } catch (SocketException) {
      final String message =
          "MqttConnection::The connection to the message broker {$uriString} could not be made.";
      throw new NoConnectionException(message);
    }
    return completer.future;
  }

  /// Create the listening stream subscription and subscribe the callbacks
  void _startListening() {
    wsClient.listen(_onData, onError: _onError, onDone: _onDone);
  }

  /// OnData listener callback
  void _onData(List<int> data) {
    MqttLogger.log("MqttConnection::_onData");
    // Protect against 0 bytes but should never happen.
    if (data.length == 0) {
      return;
    }
    readWrapper.messageBytes.addAll(data);
    // Attempt to create a message, if this works we have a full message
    // if not add the bytes to the read wrapper and wait for more bytes.
    bool messageIsValid = true;
    MqttMessage msg;
    try {
      final MqttByteBuffer messageStream = new MqttByteBuffer.fromList(data);
      msg = MqttMessage.createFrom(messageStream);
    } catch (exception) {
      MqttLogger.log("MqttConnection::_ondata - message is not valid");
      messageIsValid = false;
    }
    if (messageIsValid) {
      MqttLogger.log("MqttConnection::_onData - message received $msg");
      emitEvent(new MessageAvailable(msg));
      MqttLogger.log("MqttConnection::_onData - message processed");
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
      throw new SocketException(
          "MqttConnection::On Done called by broker, disconnecting.");
    }
  }

  /// Disconnects from the message broker
  void _disconnect() {
    if (wsClient != null) {
      wsClient.close();
    }
  }

  /// Sends the message in the stream to the broker.
  void send(MqttByteBuffer message) {
    if (_sendPadlock) {
      return;
    } else {
      _sendPadlock = true;
    }
    final typed.Uint8Buffer messageBytes = message.read(message.length);
    wsClient.add(messageBytes.toList());
    _sendPadlock = false;
  }

  // User requested disconnection
  void disconnect() {
    disconnectRequested = true;
    _onDone();
  }
}
