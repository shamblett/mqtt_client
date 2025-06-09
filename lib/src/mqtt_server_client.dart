/*
 * Package : mqtt_server_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/01/2020
 * Copyright :  S.Hamblett
 */

part of '../mqtt_server_client.dart';

class MqttServerClient extends MqttClient {
  /// The security context for secure usage
  SecurityContext securityContext = SecurityContext.defaultContext;

  /// Callback function to handle bad certificate. if true, ignore the error.
  bool Function(X509Certificate certificate)? onBadCertificate;

  /// If set use a websocket connection, otherwise use the default TCP one
  bool useWebSocket = false;

  /// If set use the alternate websocket implementation
  bool useAlternateWebSocketImplementation = false;

  /// If set use a secure connection, note TCP only, do not use for
  /// secure websockets(wss).
  bool secure = false;

  /// Max connection attempts
  final int maxConnectionAttempts;

  /// The client supports the setting of both integer and boolean raw socket options
  /// as supported by the Dart IO library [RawSocketOption](https://api.dart.dev/stable/2.19.3/dart-io/RawSocketOption-class.html) class.
  /// Please consult the documentation for the above class before using this.
  ///
  /// The socket options are set on both the initial connect and auto reconnect.
  ///
  /// The client performs no sanity checking of the values provided, what values are set are
  /// passed on to the socket untouched, as such, care should be used when using this feature,
  /// socket options are usually platform specific and can cause numerous failures at the network
  /// level for the unwary.
  ///
  /// Applicable only to TCP sockets
  List<RawSocketOption> socketOptions = <RawSocketOption>[];

  /// User definable websocket headers.
  /// This allows the specification of additional HTTP headers for setting up the connection
  /// should a broker need specific headers.
  /// The keys of the map are the header fields and the values are either String or List.
  @protected
  Map<String, dynamic>? websocketHeaders;
  set websocketHeader(Map<String, dynamic> header) {
    websocketHeaders = header;

    final connectionHandler = this.connectionHandler;
    if (connectionHandler != null) {
      connectionHandler.websocketHeaders = header;
    }
  }

  /// Initializes a new instance of the MqttServerClient class using the
  /// default Mqtt Port.
  /// The server hostname or URL to connect to
  /// The client identifier to use to connect with
  MqttServerClient(
    super.server,
    super.clientIdentifier, {
    this.maxConnectionAttempts =
        MqttClientConstants.defaultMaxConnectionAttempts,
  });

  /// Initializes a new instance of the MqttServerClient class using
  /// the supplied Mqtt Port.
  /// The server hostname to connect to
  /// The client identifier to use to connect with
  /// The port to use
  MqttServerClient.withPort(
    super.server,
    super.clientIdentifier,
    super.port, {
    this.maxConnectionAttempts =
        MqttClientConstants.defaultMaxConnectionAttempts,
  }) : super.withPort();

  /// Performs a connect to the message broker with an optional
  /// username and password for the purposes of authentication.
  /// If a username and password are supplied these will override
  /// any previously set in a supplied connection message so if you
  /// supply your own connection message and use the authenticateAs method to
  /// set these parameters do not set them again here.
  @override
  Future<MqttClientConnectionStatus?> connect([
    String? username,
    String? password,
  ]) async {
    // A server client
    MqttClientEnvironment.isWebClient = false;
    instantiationCorrect = true;
    clientEventBus = events.EventBus();
    clientEventBus?.on<DisconnectOnNoPingResponse>().listen(
      disconnectOnNoPingResponse,
    );
    clientEventBus?.on<DisconnectOnNoMessageSent>().listen(
      disconnectOnNoMessageSent,
    );
    final connectionHandler = SynchronousMqttServerConnectionHandler(
      clientEventBus,
      maxConnectionAttempts: maxConnectionAttempts,
      reconnectTimePeriod: connectTimeoutPeriod,
      socketOptions: socketOptions,
      socketTimeout: socketTimeout != null
          ? Duration(milliseconds: socketTimeout!)
          : null,
    );
    if (useWebSocket) {
      connectionHandler.secure = false;
      connectionHandler.useWebSocket = true;
      connectionHandler.useAlternateWebSocketImplementation =
          useAlternateWebSocketImplementation;
      if (connectionHandler.useAlternateWebSocketImplementation) {
        connectionHandler.securityContext = securityContext;
      }
      if (websocketHeaders != null) {
        connectionHandler.websocketHeaders = websocketHeaders;
      }
    }
    if (secure) {
      connectionHandler.secure = true;
      connectionHandler.useWebSocket = false;
      connectionHandler.useAlternateWebSocketImplementation = false;
      connectionHandler.securityContext = securityContext;
    }
    connectionHandler.onBadCertificate =
        onBadCertificate as bool Function(Object certificate)?;
    this.connectionHandler = connectionHandler;
    return await super.connect(username, password);
  }
}
