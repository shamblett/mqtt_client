/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 02/10/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// The MQTT connection class
class MqttSecureConnection extends Object with events.EventEmitter {
  /// The socket that maintains the connection to the MQTT broker.
  SecureSocket tcpClient;

  /// Sync lock object to ensure that only a single message is sent through the connection handler at once.
  bool _sendPadlock = false;

  /// The read wrapper
  ReadWrapper readWrapper;

  /// Indicates if disconnect(onDone) has been requested or not
  bool disconnectRequested = false;

  /// Trusted certificate file path for use in secure working
  String trustedCertPath;

  /// Default constructor
  MqttSecureConnection(this.trustedCertPath);

  /// Initializes a new instance of the MqttConnection class.
  MqttSecureConnection.fromConnect(String server, int port) {
    connect(server, port);
  }

  /// Connect
  Future connect(String server, int port) {
    final Completer completer = new Completer();
    MqttLogger.log("MqttSecureConnection::connect");
    try {
      // Connect and save the socket.
      final SecurityContext context = new SecurityContext();
      if (trustedCertPath != null) {
        MqttLogger.log(
            "MqttSecureConnection::connect - trusted cert path is $trustedCertPath");
        context.setTrustedCertificates(trustedCertPath);
      }
      SecureSocket
          .connect(server, port, context: context)
          .then((SecureSocket socket) {
        MqttLogger.log("MqttSecureConnection::connect - securing socket");
        tcpClient = socket;
        readWrapper = new ReadWrapper();
        SecureSocket.secure(tcpClient).then((tcpClient) {
          MqttLogger.log("MqttSecureConnection::connect - start listening");
          _startListening();
          return completer.complete();
        }).catchError((e) {
          MqttLogger.log(
              "MqttSecureConnection::fail to secure, error is ${e.toString()}");
          throw e;
        });
      }).catchError((e) => _onError(e));
    } catch (SocketException) {
      final String message =
          "MqttSecureConnection::The connection to the message broker {$server}:{$port} could not be made.";
      throw new NoConnectionException(message);
    }
    return completer.future;
  }

  /// Create the listening stream subscription and subscribe the callbacks
  void _startListening() {
    MqttLogger.log("MqttSecureConnection::_startListening");
    tcpClient.listen(_onData, onError: _onError, onDone: _onDone);
  }

  /// OnData listener callback
  void _onData(List<int> data) {
    MqttLogger.log("MqttSecureConnection::_onData");
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
      MqttLogger.log("MqttSecureConnection::_ondata - message is not valid");
      messageIsValid = false;
    }
    if (messageIsValid) {
      MqttLogger.log("MqttSecureConnection::_onData - message received $msg");
      emitEvent(new MessageAvailable(msg));
      MqttLogger.log("MqttSecureConnection::_onData - message processed");
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
          "MqttSecureConnection::On Done called by broker, disconnecting.");
    }
  }

  /// Disconnects from the message broker
  void _disconnect() {
    if (tcpClient != null) {
      tcpClient.close();
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
    tcpClient.add(messageBytes.toList());
    _sendPadlock = false;
  }

  // User requested disconnection
  void disconnect() {
    disconnectRequested = true;
    _onDone();
  }
}
