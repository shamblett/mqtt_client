/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/08/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// The MQTT connection class for the websocket interface
class MqttWsConnection extends MqttConnection {
  /// Default constructor
  MqttWsConnection(events.EventBus eventBus) : super(eventBus);

  /// Initializes a new instance of the MqttConnection class.
  MqttWsConnection.fromConnect(
      String server, int port, events.EventBus eventBus)
      : super(eventBus) {
    connect(server, port);
  }

  /// Connect
  @override
  Future<MqttClientConnectionStatus> connect(String server, int port) {
    final Completer<MqttClientConnectionStatus> completer =
        Completer<MqttClientConnectionStatus>();
    // Add the port if present
    Uri uri;
    try {
      uri = Uri.parse(server);
    } on Exception {
      final String message =
          'MqttWsConnection::The URI supplied for the WS connection is not valid - $server';
      throw NoConnectionException(message);
    }
    if (uri.scheme != 'ws' && uri.scheme != 'wss') {
      final String message =
          'MqttWsConnection::The URI supplied for the WS has an incorrect scheme - $server';
      throw NoConnectionException(message);
    }
    if (port != null) {
      uri = uri.replace(port: port);
    }
    final String uriString = uri.toString();
    MqttLogger.log('MqttWsConnection:: WS URL is $uriString');
    try {
      // Connect and save the socket.
      final List<String> protocols = <String>['mqtt', 'mqttv3.1', 'mqttv3.11'];
      WebSocket.connect(uriString, protocols: protocols).then((dynamic socket) {
        client = socket;
        readWrapper = ReadWrapper();
        messageStream = MqttByteBuffer(typed.Uint8Buffer());
        _startListening();
        completer.complete();
      }).catchError((dynamic e) {
        _onError(e);
        completer.completeError(e);
      });
    } on Exception {
      final String message =
          'MqttWsConnection::The connection to the message broker {$uriString} could not be made.';
      throw NoConnectionException(message);
    }
    return completer.future;
  }
}
