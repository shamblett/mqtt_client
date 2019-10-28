/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 02/10/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// The MQTT secure connection class
class MqttSecureConnection extends MqttConnection {
  /// Default constructor
  MqttSecureConnection(
      this.context, events.EventBus eventBus, this.onBadCertificate)
      : super(eventBus);

  /// Initializes a new instance of the MqttSecureConnection class.
  MqttSecureConnection.fromConnect(
      String server, int port, events.EventBus eventBus)
      : super(eventBus) {
    connect(server, port);
  }

  /// The security context for secure usage
  SecurityContext context;

  /// Callback function to handle bad certificate. if true, ignore the error.
  bool Function(X509Certificate certificate) onBadCertificate;

  /// Connect
  @override
  Future<MqttClientConnectionStatus> connect(String server, int port) {
    final Completer<MqttClientConnectionStatus> completer =
        Completer<MqttClientConnectionStatus>();
    MqttLogger.log('MqttSecureConnection::connect');
    try {
      SecureSocket.connect(server, port,
              onBadCertificate: onBadCertificate, context: context)
          .then((SecureSocket socket) {
        MqttLogger.log('MqttSecureConnection::connect - securing socket');
        client = socket;
        readWrapper = ReadWrapper();
        messageStream = MqttByteBuffer(typed.Uint8Buffer());
        MqttLogger.log('MqttSecureConnection::connect - start listening');
        _startListening();
        completer.complete();
      }).catchError((dynamic e) {
        _onError(e);
        completer.completeError(e);
      });
    } on SocketException catch (e) {
      final String message =
          'MqttSecureConnection::The connection to the message broker {$server}:{$port} could not be made. Error is ${e.toString()}';
      completer.completeError(e);
      throw NoConnectionException(message);
    } on HandshakeException catch (e) {
      final String message =
          'MqttSecureConnection::Handshake exception to the message broker {$server}:{$port}. Error is ${e.toString()}';
      completer.completeError(e);
      throw NoConnectionException(message);
    } on TlsException catch (e) {
      final String message =
          'MqttSecureConnection::TLS exception raised on secure connection. Error is ${e.toString()}';
      throw NoConnectionException(message);
    }
    return completer.future;
  }
}
