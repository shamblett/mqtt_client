/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// The MQTT normal(insecure TCP) connection class
class MqttNormalConnection extends MqttConnection {
  /// Default constructor
  MqttNormalConnection();

  /// Initializes a new instance of the MqttConnection class.
  MqttNormalConnection.fromConnect(String server, int port) {
    connect(server, port);
  }

  /// Connect - overridden
  Future connect(String server, int port) {
    final Completer completer = Completer();
    try {
      // Connect and save the socket.
      Socket.connect(server, port).then((socket) {
        client = socket;
        readWrapper = ReadWrapper();
        _startListening();
        completer.complete();
      }).catchError((e) {
        _onError(e);
        completer.completeError(e);
      });
    } catch (SocketException) {
      final String message =
          "MqttNormalConnection::The connection to the message broker {$server}:{$port} could not be made.";
      throw NoConnectionException(message);
    }
    return completer.future;
  }
}
