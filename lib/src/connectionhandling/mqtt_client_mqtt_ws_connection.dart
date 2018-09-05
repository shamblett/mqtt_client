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
  MqttWsConnection();

  /// Initializes a new instance of the MqttConnection class.
  MqttWsConnection.fromConnect(String server, int port) {
    connect(server, port);
  }

  /// Connect - overridden
  Future connect(String server, int port) {
    final Completer completer = Completer();
    // Add the port if present
    Uri uri;
    try {
      uri = Uri.parse(server);
    } catch (FormatException) {
      final String message =
          "MqttWsConnection::The URI supplied for the WS connection is not valid - $server";
      throw NoConnectionException(message);
    }
    if (uri.scheme != "ws") {
      final String message =
          "MqttWsConnection::The URI supplied for the WS has an incorrect scheme - $server";
      throw NoConnectionException(message);
    }
    if (port != null) {
      uri = uri.replace(port: port);
    }
    final String uriString = uri.toString();
    MqttLogger.log("MqttWsConnection:: WS URL is $uriString");
    try {
      // Connect and save the socket.
      WebSocket.connect(uriString).then((socket) {
        client = socket;
        readWrapper = ReadWrapper();
        _startListening();
        completer.complete();
      }).catchError((e) => _onError(e));
    } catch (SocketException) {
      final String message =
          "MqttWsConnection::The connection to the message broker {$uriString} could not be made.";
      throw NoConnectionException(message);
    }
    return completer.future;
  }
}
