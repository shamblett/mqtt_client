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
    this.readState = ConnectionReadState.header;
    this.messageBytes = new List<int>();
    this.totalBytes = 1; // default to header read size.
    this.nextReadSize = this.totalBytes;
  }

  /// The total bytes expected to be read from from the header of content
  int totalBytes;

  /// The bytes associated with the message being read.
  List<int> messageBytes;

  /// The amount of content to read during the next read.
  int nextReadSize;

  /// What is the connection currently reading.
  ConnectionReadState readState;

  /// A boolean that indicates whether the message read is complete
  bool get isReadComplete => messageBytes.length < totalBytes;

  /// Recalculates the number of bytes to read given the expected total size and the amount read so far.
  void recalculateNextReadSize() {
    if (totalBytes == 0) {
      throw new SocketException(
          "Total ReadBytes is 0, cannot calculate next read size.");
    }
    this.nextReadSize = totalBytes - messageBytes.length;
  }
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
    // Protect against 0 bytes but should never happen.
    if (data.length == 0) {
      return;
    }
    readWrapper.messageBytes.addAll(data);
    if (readWrapper.readState == ConnectionReadState.header) {
      final typed.Uint8Buffer buff = new typed.Uint8Buffer();
      buff.addAll(data);
      final MqttByteBuffer stream = new MqttByteBuffer(buff);
      final typed.Uint8Buffer lengthBytes = MqttHeader.readLengthBytes(stream);
      final int remainingLength = MqttHeader.calculateLength(lengthBytes);
      if (remainingLength == 0) {
        emitEvent(new MessageDataAvailable(readWrapper.messageBytes));
      } else {
        // Total bytes of content is the remaining length plus the header.
        readWrapper.totalBytes =
            remainingLength + readWrapper.messageBytes.length;
        readWrapper.recalculateNextReadSize();
        readWrapper.readState = ConnectionReadState.content;
      }
    } else if (readWrapper.readState == ConnectionReadState.content) {
      // If we haven't yet read all of the message repeat the read otherwise if
      // we're finished process the message and switch back to waiting for the next header.
      if (readWrapper.isReadComplete) {
        // Reset the read buffer to accommodate the remaining length (last - what was read)
        readWrapper.recalculateNextReadSize();
      } else {
        readWrapper.readState = ConnectionReadState.header;
        emitEvent(new MessageDataAvailable(readWrapper.messageBytes));
      }
    }
    // If we are reading a header then recreate the read wrapper for the next message
    if (readWrapper.readState == ConnectionReadState.header) {
      readWrapper = new ReadWrapper();
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
