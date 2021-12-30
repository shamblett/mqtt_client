/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/08/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_server_client;

/// The MQTT server connection class for the websocket interface
class MqttServerWsConnection extends MqttServerConnection {
  /// Default constructor
  MqttServerWsConnection(events.EventBus? eventBus) : super(eventBus);

  /// Initializes a new instance of the MqttConnection class.
  MqttServerWsConnection.fromConnect(
      String server, int port, events.EventBus eventBus)
      : super(eventBus) {
    connect(server, port);
  }

  /// The websocket subprotocol list
  List<String> protocols = MqttClientConstants.protocolsMultipleDefault;

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
              protocols: protocols.isNotEmpty ? protocols : null)
          .then((dynamic socket) {
        client = socket;
        readWrapper = ReadWrapper();
        messageStream = MqttByteBuffer(typed.Uint8Buffer());
        _startListening();
        completer.complete();
      }).catchError((dynamic e) {
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
          .then((dynamic socket) {
        client = socket;
        _startListening();
        completer.complete();
      }).catchError((dynamic e) {
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

  /// User requested or auto disconnect disconnection
  @override
  void disconnect({bool auto = false}) {
    if (auto) {
      client = null;
    } else {
      onDone();
    }
  }

  /// OnDone listener callback
  @override
  void onDone() {
    _disconnect();
    if (onDisconnected != null) {
      MqttLogger.log(
          'MqttWsConnection::::onDone - calling disconnected callback');
      onDisconnected!();
    }
  }

  void _disconnect() {
    if (client != null) {
      client.close();
      client = null;
    }
  }

  /// Stops listening and closes the socket immediately.
  @override
  void stopListening() {
    if (client != null) {
      listener?.cancel();
      client.close();
    }
  }
}
