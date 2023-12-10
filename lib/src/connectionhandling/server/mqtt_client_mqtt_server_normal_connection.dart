/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt_server_client.dart';

/// The MQTT normal(insecure TCP) server connection class
class MqttServerNormalConnection extends MqttServerConnection<Socket> {
  /// Default constructor
  MqttServerNormalConnection(super.eventBus, super.socketOptions);

  /// Initializes a new instance of the MqttConnection class.
  MqttServerNormalConnection.fromConnect(String server, int port,
      events.EventBus eventBus, List<RawSocketOption> socketOptions)
      : super(eventBus, socketOptions) {
    connect(server, port);
  }

  /// Connect
  @override
  Future<MqttClientConnectionStatus?> connect(String server, int port) {
    final completer = Completer<MqttClientConnectionStatus?>();
    MqttLogger.log('MqttNormalConnection::connect - entered');
    try {
      // Connect and save the socket.
      Socket.connect(server, port).then((socket) {
        // Socket options
        final applied = _applySocketOptions(socket, socketOptions);
        if (applied) {
          MqttLogger.log(
              'MqttNormalConnection::connect - socket options applied');
        }
        client = socket;
        readWrapper = ReadWrapper();
        messageStream = MqttByteBuffer(typed.Uint8Buffer());
        _startListening();
        completer.complete();
      }).catchError((e) {
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
      Socket.connect(server, port).then((socket) {
        // Socket options
        final applied = _applySocketOptions(socket, socketOptions);
        if (applied) {
          MqttLogger.log(
              'MqttNormalConnection::connectAuto - socket options applied');
        }
        client = socket;
        _startListening();
        completer.complete();
      }).catchError((e) {
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
    client?.destroy();
    client?.close();
  }

  /// Closes and dispose the socket immediately.
  @override
  void disposeClient() {
    closeClient();
    if (client != null) {
      client = null;
    }
  }

  /// Implement stream subscription
  @override
  StreamSubscription onListen() {
    final socket = client;
    if (socket == null) {
      throw StateError('socket is null');
    }

    return socket.listen(onData, onError: onError, onDone: onDone);
  }
}
