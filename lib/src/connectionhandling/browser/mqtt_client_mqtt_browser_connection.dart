/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_browser_client;

/// The MQTT browser connection base class
class MqttBrowserConnection extends MqttConnectionBase {
  /// Default constructor
  MqttBrowserConnection(clientEventBus) : super(clientEventBus);

  /// Initializes a new instance of the MqttBrowserConnection class.
  MqttBrowserConnection.fromConnect(server, port, clientEventBus)
      : super(clientEventBus) {
    connect(server, port);
  }

  /// Connect, must be overridden in connection classes
  @override
  Future<void> connect(String server, int port) {
    final completer = Completer<void>();
    return completer.future;
  }

  /// Connect for auto reconnect , must be overridden in connection classes
  @override
  Future<void> connectAuto(String server, int port) {
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
        onDone();
      });
      client.onMessage.listen((MessageEvent e) {
        _onData(e.data);
      });
      client.onError.listen((e) {
        MqttLogger.log(
            'MqttBrowserConnection::_startListening - websocket has errored');
        onError(e);
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
      MqttMessage? msg;

      try {
        msg = MqttMessage.createFrom(messageStream);
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
            'MqttBrowserConnection::_onData - message received ', msg);
        if (!clientEventBus!.streamController.isClosed) {
          if (msg!.header!.messageType == MqttMessageType.connectAck) {
            clientEventBus!.fire(ConnectAckMessageAvailable(msg));
          } else {
            clientEventBus!.fire(MessageAvailable(msg));
          }
          MqttLogger.log(
              'MqttBrowserConnection::_onData - message available event fired');
        } else {
          MqttLogger.log(
              'MqttBrowserConnection::_onData - WARN - message available event not fired, event bus is closed');
        }
      }
    }
  }

  /// Sends the message in the stream to the broker.
  void send(MqttByteBuffer message) {
    final messageBytes = message.read(message.length);
    var buffer = messageBytes.buffer;
    var bData = ByteData.view(buffer);
    client?.sendTypedData(bData);
  }
}
