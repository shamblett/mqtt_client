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


/// The MQTT connection class
class MqttConnection {
  /// The socket that maintains the connection to the MQTT broker.
  Socket tcpClient;

  /// Sync lock object to ensure that only a single message is sent through the connection handler at once.
  bool _sendPadlock = false;

  /// Initializes a new instance of the MqttConnection class.
  MqttConnection(String server, int port) {
    try {
      // Connect and save the socket. Do this lazily,
      // we wont process anything until the connection state moves to
      // connected.
      Socket.connect(server, port).then((socket) {
        tcpClient = socket;
        _startListening();

      });
    } catch (SocketException) {
      final String message =
          "The connection to the message broker {$server}:{$port} could not be made.";
      throw new NoConnectionException(message);
    }
  }

  /// Create the listening stream subscription and subscribe the callbacks
  void _startListening() {
    tcpClient.listen(_onData,
        onError: _onError,
        onDone: _onDone);
  }

  /// OnData listener callback
  void _onData(List<int> data) {

  }

  /// OnError listener callback
  void _onError(Error error) {

  }

  /// OnDone listener callback
  void _onDone() {

  }

  /// Disconnects from the message broker
  void _disconnect() {
    tcpClient.close();
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

  /// Initiate a new connection to a message broker
  static MqttConnection connect(String server, int port) {
    return new MqttConnection(server, port);
  }
}
