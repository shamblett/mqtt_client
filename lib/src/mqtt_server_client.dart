/*
 * Package : mqtt_server_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/01/2020
 * Copyright :  S.Hamblett
 */

part of mqtt_server_client;

class MqttServerClient extends MqttClient {
  /// Initializes a new instance of the MqttServerClient class using the
  /// default Mqtt Port.
  /// The server hostname to connect to
  /// The client identifier to use to connect with
  MqttServerClient(String server, String clientIdentifier)
      : super(server, clientIdentifier);

  /// Initializes a new instance of the MqttServerClient class using
  /// the supplied Mqtt Port.
  /// The server hostname to connect to
  /// The client identifier to use to connect with
  /// The port to use
  MqttServerClient.withPort(String server, String clientIdentifier, int port)
      : super.withPort(server, clientIdentifier, port);

  /// The security context for secure usage
  SecurityContext securityContext = SecurityContext.defaultContext;

  /// Callback function to handle bad certificate. if true, ignore the error.
  bool Function(X509Certificate certificate) onBadCertificate;

  /// If set use a websocket connection, otherwise use the default TCP one
  bool useWebSocket = false;

  /// If set use the alternate websocket implementation
  bool useAlternateWebSocketImplementation = false;

  /// If set use a secure connection, note TCP only, do not use for
  /// secure websockets(wss).
  bool secure = false;

  /// Performs a connect to the message broker with an optional
  /// username and password for the purposes of authentication.
  /// If a username and password are supplied these will override
  /// any previously set in a supplied connection message so if you
  /// supply your own connection message and use the authenticateAs method to
  /// set these parameters do not set them again here.
  @override
  Future<MqttClientConnectionStatus> connect(
      [String username, String password]) async {
    instantiationCorrect = true;
    clientEventBus = events.EventBus();
    connectionHandler = SynchronousMqttConnectionHandler(clientEventBus);
    if (useWebSocket) {
      connectionHandler.secure = false;
      connectionHandler.useWebSocket = true;
      connectionHandler.useAlternateWebSocketImplementation =
          useAlternateWebSocketImplementation;
      if (websocketProtocolString != null) {
        connectionHandler.websocketProtocols = websocketProtocolString;
      }
    }
    if (secure) {
      connectionHandler.secure = true;
      connectionHandler.useWebSocket = false;
      connectionHandler.useAlternateWebSocketImplementation = false;
      connectionHandler.securityContext = securityContext;
      connectionHandler.onBadCertificate = onBadCertificate;
    }
    return await super.connect(username, password);
  }
}
