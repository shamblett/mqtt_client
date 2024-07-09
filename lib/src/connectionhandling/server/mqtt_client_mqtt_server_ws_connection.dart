/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/08/2017
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt_server_client.dart';

/// The MQTT server connection class for the websocket interface
class MqttServerWsConnection extends MqttServerConnection<WebSocket> {
  /// Default constructor
  MqttServerWsConnection(super.eventBus, super.socketOptions);

  /// Initializes a new instance of the MqttConnection class.
  MqttServerWsConnection.fromConnect(String server, int port,
      events.EventBus eventBus, List<RawSocketOption> socketOptions)
      : super(eventBus, socketOptions) {
    connect(server, port);
  }

  /// The websocket subprotocol list
  List<String> protocols = MqttClientConstants.protocolsMultipleDefault;

  /// User defined websocket headers
  Map<String, dynamic>? headers;

  /// Connect
  @override
  Future<MqttClientConnectionStatus?> connect(String server, int port) {
    final completer = Completer<MqttClientConnectionStatus?>();
    MqttLogger.log('MqttWsConnection::connect - entered');
    // Add the port if present
    Uri uri;
    try {
      uri = Uri.parse(server);
    } on Exception {
      final message = 'MqttWsConnection::connect - The URI supplied for the WS '
          'connection is not valid - $server';
      throw NoConnectionException(message);
    }
    if (uri.scheme != 'ws' && uri.scheme != 'wss') {
      final message =
          'MqttWsConnection::connect - The URI supplied for the WS has '
          'an incorrect scheme - $server';
      throw NoConnectionException(message);
    }

    uri = uri.replace(port: port);

    final uriString = uri.toString();
    MqttLogger.log(
        'MqttWsConnection::connect - WS URL is $uriString, protocols are $protocols');
    try {
      // Connect and save the socket.
      WebSocket.connect(uriString,
              protocols: protocols.isNotEmpty ? protocols : null,
              headers: headers)
          .then((socket) {
        client = socket;
        readWrapper = ReadWrapper();
        messageStream = MqttByteBuffer(typed.Uint8Buffer());
        _startListening();
        completer.complete();
      }).catchError((e) {
        onError(e);
        completer.completeError(e);
      });
    } on Exception {
      final message =
          'MqttWsConnection::connect - The connection to the message broker '
          '{$uriString} could not be made.';
      throw NoConnectionException(message);
    }
    return completer.future;
  }

  /// Connect Auto
  @override
  Future<MqttClientConnectionStatus?> connectAuto(String server, int port) {
    final completer = Completer<MqttClientConnectionStatus?>();
    MqttLogger.log('MqttWsConnection::connectAuto - entered');
    // Add the port if present
    Uri uri;
    try {
      uri = Uri.parse(server);
    } on Exception {
      final message =
          'MqttWsConnection::connectAuto - The URI supplied for the WS '
          'connection is not valid - $server';
      throw NoConnectionException(message);
    }
    if (uri.scheme != 'ws' && uri.scheme != 'wss') {
      final message =
          'MqttWsConnection::connectAuto - The URI supplied for the WS has '
          'an incorrect scheme - $server';
      throw NoConnectionException(message);
    }

    uri = uri.replace(port: port);

    final uriString = uri.toString();
    MqttLogger.log(
        'MqttWsConnection::connectAuto - WS URL is $uriString, protocols are $protocols');
    try {
      // Connect and save the socket.
      WebSocket.connect(uriString,
              protocols: protocols.isNotEmpty ? protocols : null)
          .then((socket) {
        client = socket;
        _startListening();
        completer.complete();
      }).catchError((e) {
        onError(e);
        completer.completeError(e);
      });
    } on Exception {
      final message =
          'MqttWsConnection::connectAuto - The connection to the message broker '
          '{$uriString} could not be made.';
      throw NoConnectionException(message);
    }
    return completer.future;
  }

  /// Sends the message in the stream to the broker.
  @override
  void send(MqttByteBuffer message) {
    final messageBytes = message.read(message.length);
    client?.add(messageBytes.toList());
  }

  /// Stops listening the socket immediately.
  @override
  void stopListening() {
    for (final listener in listeners) {
      listener.cancel();
    }

    listeners.clear();
  }

  /// Closes the socket immediately.
  @override
  void closeClient() {
    client?.close();
  }

  /// Closes and dispose the socket immediately.
  @override
  void disposeClient() {
    closeClient();
    client = null;
  }

  /// Implement stream subscription
  @override
  StreamSubscription onListen() {
    final webSocket = client;
    if (webSocket == null) {
      throw StateError('webSocket is null');
    }

    return webSocket.listen(onData, onError: onError, onDone: onDone);
  }
}
