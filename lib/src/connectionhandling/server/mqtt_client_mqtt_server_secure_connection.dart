/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 02/10/2017
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt_server_client.dart';

/// The MQTT server secure connection class
class MqttServerSecureConnection extends MqttServerConnection<SecureSocket> {
  /// Default constructor
  MqttServerSecureConnection(this.context, events.EventBus? eventBus,
      this.onBadCertificate, List<RawSocketOption> socketOptions)
      : super(eventBus, socketOptions);

  /// Initializes a new instance of the MqttSecureConnection class.
  MqttServerSecureConnection.fromConnect(String server, int port,
      events.EventBus eventBus, List<RawSocketOption> socketOptions)
      : super(eventBus, socketOptions) {
    connect(server, port);
  }

  /// The security context for secure usage
  SecurityContext? context;

  /// Callback function to handle bad certificate. if true, ignore the error.
  bool Function(X509Certificate certificate)? onBadCertificate;

  /// Connect
  @override
  Future<MqttClientConnectionStatus?> connect(String server, int port) {
    final completer = Completer<MqttClientConnectionStatus?>();
    MqttLogger.log('MqttSecureConnection::connect - entered');
    try {
      SecureSocket.connect(server, port,
              onBadCertificate: onBadCertificate, context: context)
          .then((socket) {
        MqttLogger.log('MqttSecureConnection::connect - securing socket');
        // Socket options
        final applied = _applySocketOptions(socket, socketOptions);
        if (applied) {
          MqttLogger.log(
              'MqttSecureConnection::connect - socket options applied');
        }
        client = socket;
        readWrapper = ReadWrapper();
        messageStream = MqttByteBuffer(typed.Uint8Buffer());
        MqttLogger.log('MqttSecureConnection::connect - start listening');
        _startListening();
        completer.complete();
      }).catchError((e) {
        onError(e);
        completer.completeError(e);
      });
    } on SocketException catch (e) {
      final message =
          'MqttSecureConnection::connect - The connection to the message broker '
          '{$server}:{$port} could not be made. Error is ${e.toString()}';
      completer.completeError(e);
      throw NoConnectionException(message);
    } on HandshakeException catch (e) {
      final message =
          'MqttSecureConnection::connect - Handshake exception to the message broker '
          '{$server}:{$port}. Error is ${e.toString()}';
      completer.completeError(e);
      throw NoConnectionException(message);
    } on TlsException catch (e) {
      final message = 'MqttSecureConnection::TLS exception raised on secure '
          'connection. Error is ${e.toString()}';
      throw NoConnectionException(message);
    }
    return completer.future;
  }

  /// Connect Auto
  @override
  Future<MqttClientConnectionStatus?> connectAuto(String server, int port) {
    final completer = Completer<MqttClientConnectionStatus?>();
    MqttLogger.log('MqttSecureConnection::connectAuto - entered');
    try {
      SecureSocket.connect(server, port,
              onBadCertificate: onBadCertificate, context: context)
          .then((socket) {
        MqttLogger.log('MqttSecureConnection::connectAuto - securing socket');
        // Socket options
        final applied = _applySocketOptions(socket, socketOptions);
        if (applied) {
          MqttLogger.log(
              'MqttSecureConnection::connectAuto - socket options applied');
        }
        client = socket;
        MqttLogger.log('MqttSecureConnection::connectAuto - start listening');
        _startListening();
        completer.complete();
      }).catchError((e) {
        onError(e);
        completer.completeError(e);
      });
    } on SocketException catch (e) {
      final message =
          'MqttSecureConnection::connectAuto - The connection to the message broker '
          '{$server}:{$port} could not be made. Error is ${e.toString()}';
      completer.completeError(e);
      throw NoConnectionException(message);
    } on HandshakeException catch (e) {
      final message =
          'MqttSecureConnection::connectAuto - Handshake exception to the message broker '
          '{$server}:{$port}. Error is ${e.toString()}';
      completer.completeError(e);
      throw NoConnectionException(message);
    } on TlsException catch (e) {
      final message =
          'MqttSecureConnection::connectAuto - TLS exception raised on secure '
          'connection. Error is ${e.toString()}';
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
