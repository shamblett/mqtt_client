/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/08/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_browser_client;

/// The MQTT connection class for the browser websocket interface
class MqttBrowserWsConnection extends MqttBrowserConnection {
  /// Default constructor
  MqttBrowserWsConnection(events.EventBus eventBus) : super(eventBus);

  /// Initializes a new instance of the MqttConnection class.
  MqttBrowserWsConnection.fromConnect(
      String server, int port, events.EventBus eventBus)
      : super(eventBus) {
    connect(server, port);
  }

  /// The websocket subprotocol list
  List<String> protocols = MqttClientConstants.protocolsMultipleDefault;

  /// Connect
  @override
  Future<MqttClientConnectionStatus> connect(String server, int port) {
    final completer = Completer<MqttClientConnectionStatus>();
    // Add the port if present
    Uri uri;
    try {
      uri = Uri.parse(server);
    } on Exception {
      final message =
          'MqttBrowserWsConnection::connect - The URI supplied for the WS '
          'connection is not valid - $server';
      throw NoConnectionException(message);
    }
    if (uri.scheme != 'ws' && uri.scheme != 'wss') {
      final message =
          'MqttBrowserWsConnection::connect - The URI supplied for the WS has '
          'an incorrect scheme - $server';
      throw NoConnectionException(message);
    }
    if (port != null) {
      uri = uri.replace(port: port);
    }
    final uriString = uri.toString();
    MqttLogger.log('MqttBrowserWsConnection::connect -  WS URL is $uriString');
    try {
      // Connect and save the socket.
      client = WebSocket(uriString, protocols);
      client.binaryType = 'arraybuffer';
      messageStream = MqttByteBuffer(typed.Uint8Buffer());
      var closeEvents;
      var errorEvents;
      client.onOpen.listen((e) {
        MqttLogger.log('MqttBrowserWsConnection::connect - websocket is open');
        closeEvents.cancel();
        errorEvents.cancel();
        _startListening();
        return completer.complete();
      });

      closeEvents = client.onClose.listen((e) {
        MqttLogger.log(
            'MqttBrowserWsConnection::connect - websocket is closed');
        closeEvents.cancel();
        errorEvents.cancel();
        return completer.complete(MqttClientConnectionStatus());
      });
      errorEvents = client.onError.listen((e) {
        MqttLogger.log(
            'MqttBrowserWsConnection::connect - websocket has errored');
        closeEvents.cancel();
        errorEvents.cancel();
        return completer.complete(MqttClientConnectionStatus());
      });
    } on Exception {
      final message =
          'MqttBrowserWsConnection::connect - The connection to the message broker '
          '{$uriString} could not be made.';
      throw NoConnectionException(message);
    }
    MqttLogger.log('MqttBrowserWsConnection::connect - connection is waiting');
    return completer.future;
  }
}
