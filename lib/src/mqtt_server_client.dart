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

  /// The server side connection handler
  MqttConnectionHandler serverConnectionHandler;

  /// The security context for secure usage
  SecurityContext securityContext = SecurityContext.defaultContext;

  /// Callback function to handle bad certificate. if true, ignore the error.
  bool Function(X509Certificate certificate) onBadCertificate;

  /// If set use a websocket connection, otherwise use the default TCP one
  bool useWebSocket = false;

  /// If set use the alternate websocket implementation
  bool useAlternateWebSocketImplementation = false;

  List<String> _websocketProtocols;

  /// User definable websocket protocols. Use this for non default websocket
  /// protocols only if your broker needs this. There are two defaults in
  /// MqttWsConnection class, the multiple protocol is the default. Some brokers
  /// will not accept a list and only expect a single protocol identifier,
  /// in this case use the single protocol default. You can supply your own
  /// list, or to disable this entirely set the protocols to an
  /// empty list , i.e [].
  set websocketProtocols(List<String> protocols) {
    _websocketProtocols = protocols;
    if (serverConnectionHandler != null) {
      serverConnectionHandler.websocketProtocols = protocols;
    }
  }

  /// If set use a secure connection, note TCP only, do not use for
  /// secure websockets(wss).
  bool secure = false;

  /// Performs a connect to the message broker with an optional
  /// username and password for the purposes of authentication.
  /// If a username and password are supplied these will override
  /// any previously set in a supplied connection message so if you
  /// supply your own connection message and use the authenticateAs method to
  /// set these parameters do not set them again here.
  Future<MqttClientConnectionStatus> connect(
      [String username, String password]) async {
    checkCredentials(username, password);
    // Set the authentication parameters in the connection
    // message if we have one.
    connectionMessage?.authenticateAs(username, password);

    // Do the connection
    clientEventBus = events.EventBus();
    serverConnectionHandler = SynchronousMqttConnectionHandler(clientEventBus);
    if (useWebSocket) {
      serverConnectionHandler.secure = false;
      serverConnectionHandler.useWebSocket = true;
      serverConnectionHandler.useAlternateWebSocketImplementation =
          useAlternateWebSocketImplementation;
      if (_websocketProtocols != null) {
        serverConnectionHandler.websocketProtocols = _websocketProtocols;
      }
    }
    if (secure) {
      serverConnectionHandler.secure = true;
      serverConnectionHandler.useWebSocket = false;
      serverConnectionHandler.useAlternateWebSocketImplementation = false;
      serverConnectionHandler.securityContext = securityContext;
      serverConnectionHandler.onBadCertificate = onBadCertificate;
    }
    serverConnectionHandler.onDisconnected = internalDisconnect;
    serverConnectionHandler.onConnected = onConnected;
    publishingManager =
        PublishingManager(serverConnectionHandler, clientEventBus);
    subscriptionsManager = SubscriptionsManager(
        serverConnectionHandler, publishingManager, clientEventBus);
    subscriptionsManager.onSubscribed = onSubscribed;
    subscriptionsManager.onUnsubscribed = onUnsubscribed;
    subscriptionsManager.onSubscribeFail = onSubscribeFail;
    updates = subscriptionsManager.subscriptionNotifier.changes;
    keepAlive =
        MqttConnectionKeepAlive(serverConnectionHandler, keepAlivePeriod);
    if (pongCallback != null) {
      keepAlive.pongCallback = pongCallback;
    }
    final connectMessage = getConnectMessage(username, password);
    connectionHandler = serverConnectionHandler;
    return serverConnectionHandler.connect(server, port, connectMessage);
  }
}
