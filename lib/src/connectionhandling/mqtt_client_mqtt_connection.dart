/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Controls the read state used during async reads.
enum ConnectionReadState {
  /// Reading a message header.
  header,

  /// Reading message content.
  content
}

/// State and logic used to read from the underlying network stream.
class ReadWrapper {
  /// Creates a new ReadWrapper that wraps the state used to read a message from a stream.
  ReadWrapper() {
    this.messageBytes = new List<int>();
  }

  /// The bytes associated with the message being read.
  List<int> messageBytes;
}

/// The MQTT connection class
class MqttConnection extends Object with events.EventEmitter {
  /// The socket that maintains the connection to the MQTT broker.
  Socket tcpClient;

  /// Sync lock object to ensure that only a single message is sent through the connection handler at once.
  bool _sendPadlock = false;

  /// The read wrapper
  ReadWrapper readWrapper;

  /// Default constructor
  MqttConnection();

  /// Initializes a new instance of the MqttConnection class.
  MqttConnection.fromConnect(String server, int port) {
    connect(server, port);
  }

  /// Connect
  Future connect(String server, int port) {
    final Completer completer = new Completer();
    try {
      // Connect and save the socket. Do this lazily,
      // we wont process anything until the connection state moves to
      // connected.
      Socket.connect(server, port).then((socket) {
        tcpClient = socket;
        readWrapper = new ReadWrapper();
        _startListening();
        return completer.complete();
      }).catchError((e) => _onError(e));
    } catch (SocketException) {
      final String message =
          "MqttConnection::The connection to the message broker {$server}:{$port} could not be made.";
      throw new NoConnectionException(message);
    }
    return completer.future;
  }

  /// Create the listening stream subscription and subscribe the callbacks
  void _startListening() {
    tcpClient.listen(_onData, onError: _onError, onDone: _onDone);
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
    }
  }

  /// OnError listener callback
  void _onError(error) {
    _disconnect();
  }

  /// OnDone listener callback
  void _onDone() {
    // We should never be done
    _disconnect();
    throw new SocketException("MqttConnection::On Done called, disconnecting.");
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
}
