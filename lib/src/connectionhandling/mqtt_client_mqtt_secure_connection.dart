/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 02/10/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// The MQTT secure connection class
class MqttSecureConnection extends MqttConnection {
  /// Trusted certificate file path for use in secure working
  String trustedCertPath;

  /// Private key file path
  String privateKeyFilePath;

  /// Default constructor
  MqttSecureConnection(this.trustedCertPath, this.privateKeyFilePath);

  /// Initializes a new instance of the MqttSecureConnection class.
  MqttSecureConnection.fromConnect(String server, int port) {
    connect(server, port);
  }

  /// Connect - overridden
  Future connect(String server, int port) {
    final Completer completer = new Completer();
    MqttLogger.log("MqttSecureConnection::connect");
    try {
      // Connect and save the socket.
      final SecurityContext context = SecurityContext.defaultContext;
      if (trustedCertPath != null) {
        MqttLogger.log(
            "MqttSecureConnection::connect - trusted cert path is $trustedCertPath");
        context.setTrustedCertificates(trustedCertPath);
      }
      if (privateKeyFilePath != null) {
        MqttLogger.log(
            "MqttSecureConnection::connect - private key file path is $privateKeyFilePath");
        context.usePrivateKey(privateKeyFilePath);
      }
      SecureSocket.connect(server, port).then((SecureSocket socket) {
        MqttLogger.log("MqttSecureConnection::connect - securing socket");
        client = socket;
        readWrapper = new ReadWrapper();
        MqttLogger.log("MqttSecureConnection::connect - start listening");
        _startListening();
        return completer.complete();
      }).catchError((e) => _onError(e));
    } on SocketException catch (e) {
      final String message =
          "MqttSecureConnection::The connection to the message broker {$server}:{$port} could not be made. Error is ${e
          .toString()}";
      throw new NoConnectionException(message);
    } on HandshakeException catch (e) {
      final String message =
          "MqttSecureConnection::Handshake exception to the message broker {$server}:{$port}. Error is ${e
          .toString()}";
      throw new NoConnectionException(message);
    }
    return completer.future;
  }
}
