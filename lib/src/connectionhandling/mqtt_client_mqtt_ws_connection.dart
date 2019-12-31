/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/08/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

// ignore_for_file: unnecessary_final
// ignore_for_file: omit_local_variable_types
// ignore_for_file: avoid_print
// ignore_for_file: avoid_annotating_with_dynamic
// ignore_for_file: avoid_types_on_closure_parameters

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

  /// The default websocket subprotocol list
  static const List<String> protocolsMultipleDefault = <String>[
    'mqtt',
    'mqttv3.1',
    'mqttv3.11'
  ];

  /// The default websocket subprotocol list for brokers who expect
  /// this field to be a single entry
  static const List<String> protocolsSingleDefault = <String>['mqtt'];

  /// The websocket subprotocol list
  List<String> protocols = protocolsMultipleDefault;

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
      final String message = 'MqttWsConnection::The URI supplied for the WS '
          'connection is not valid - $server';
      throw NoConnectionException(message);
    }
    if (uri.scheme != 'ws' && uri.scheme != 'wss') {
      final String message =
          'MqttWsConnection::The URI supplied for the WS has '
          'an incorrect scheme - $server';
      throw NoConnectionException(message);
    }
    if (port != null) {
      uri = uri.replace(port: port);
    }
    final String uriString = uri.toString();
    MqttLogger.log(
        'MqttWsConnection:: WS URL is $uriString, protocols are $protocols');
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
        _onError(e);
        completer.completeError(e);
      });
    } on Exception {
      final String message =
          'MqttWsConnection::The connection to the message broker '
          '{$uriString} could not be made.';
      throw NoConnectionException(message);
    }
    return completer.future;
  }
}
