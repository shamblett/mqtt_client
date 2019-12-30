/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

// ignore_for_file: unnecessary_final
// ignore_for_file: omit_local_variable_types
// ignore_for_file: avoid_print
// ignore_for_file: avoid_annotating_with_dynamic

/// The MQTT normal(insecure TCP) connection class
class MqttNormalConnection extends MqttConnection {
  /// Default constructor
  MqttNormalConnection(events.EventBus eventBus) : super(eventBus);

  /// Initializes a new instance of the MqttConnection class.
  MqttNormalConnection.fromConnect(
      String server, int port, events.EventBus eventBus)
      : super(eventBus) {
    connect(server, port);
  }

  /// Connect - overridden
  @override
  Future<MqttClientConnectionStatus> connect(String server, int port) {
    final Completer<MqttClientConnectionStatus> completer =
        Completer<MqttClientConnectionStatus>();
    try {
      // Connect and save the socket.
      Socket.connect(server, port).then((dynamic socket) {
        client = socket;
        readWrapper = ReadWrapper();
        messageStream = MqttByteBuffer(typed.Uint8Buffer());
        _startListening();
        completer.complete();
      }).catchError((dynamic e) {
        _onError(e);
        completer.completeError(e);
      });
    } on Exception catch (e) {
      completer.completeError(e);
      final String message =
          'MqttNormalConnection::The connection to the message '
          'broker {$server}:{$port} could not be made.';
      throw NoConnectionException(message);
    }
    return completer.future;
  }
}
