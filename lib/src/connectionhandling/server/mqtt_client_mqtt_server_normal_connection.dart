/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_server_client;

/// The MQTT normal(insecure TCP) server connection class
class MqttServerNormalConnection extends MqttServerConnection {
  /// Default constructor
  MqttServerNormalConnection(events.EventBus? eventBus) : super(eventBus);

  /// Initializes a new instance of the MqttConnection class.
  MqttServerNormalConnection.fromConnect(
      String server, int port, events.EventBus eventBus)
      : super(eventBus) {
    connect(server, port);
  }

  /// Connect
  @override
  Future<MqttClientConnectionStatus?> connect(String server, int port) {
    final completer = Completer<MqttClientConnectionStatus?>();
    MqttLogger.log('MqttNormalConnection::connect - entered');
    try {
      // Connect and save the socket.
      Socket.connect(server, port).then((dynamic socket) {
        client = socket;
        readWrapper = ReadWrapper();
        messageStream = MqttByteBuffer(typed.Uint8Buffer());
        _startListening();
        completer.complete();
      }).catchError((dynamic e) {
        onError(e);
        completer.completeError(e);
      });
    } on SocketException catch (e) {
      final message =
          'MqttNormalConnection::connect - The connection to the message broker '
          '{$server}:{$port} could not be made. Error is ${e.toString()}';
      completer.completeError(e);
      throw NoConnectionException(message);
    } on Exception catch (e) {
      completer.completeError(e);
      final message =
          'MqttNormalConnection::Connect - The connection to the message '
          'broker {$server}:{$port} could not be made.';
      throw NoConnectionException(message);
    }
    return completer.future;
  }

  /// Connect Auto
  @override
  Future<MqttClientConnectionStatus?> connectAuto(String server, int port) {
    final completer = Completer<MqttClientConnectionStatus?>();
    MqttLogger.log('MqttNormalConnection::connectAuto - entered');
    try {
      // Connect and save the socket.
      Socket.connect(server, port).then((dynamic socket) {
        client = socket;
        _startListening();
        completer.complete();
      }).catchError((dynamic e) {
        onError(e);
        completer.completeError(e);
      });
    } on SocketException catch (e) {
      final message =
          'MqttNormalConnection::connectAuto - The connection to the message broker '
          '{$server}:{$port} could not be made. Error is ${e.toString()}';
      completer.completeError(e);
      throw NoConnectionException(message);
    } on Exception catch (e) {
      completer.completeError(e);
      final message =
          'MqttNormalConnection::ConnectAuto - The connection to the message '
          'broker {$server}:{$port} could not be made.';
      throw NoConnectionException(message);
    }
    return completer.future;
  }
}
