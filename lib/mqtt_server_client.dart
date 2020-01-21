/*
 * Package : mqtt_server_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 20/01/2020
 * Copyright :  S.Hamblett
 */

library mqtt_server_client;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:event_bus/event_bus.dart' as events;
import 'package:typed_data/typed_data.dart' as typed;
import 'mqtt_client.dart';

part 'src/connectionhandling/mqtt_client_mqtt_connection_handler.dart';
part 'src/connectionhandling/mqtt_client_mqtt_normal_connection.dart';
part 'src/connectionhandling/mqtt_client_mqtt_secure_connection.dart';
part 'src/connectionhandling/mqtt_client_mqtt_ws2_connection.dart';
part 'src/connectionhandling/mqtt_client_mqtt_ws_connection.dart';
part 'src/connectionhandling/mqtt_client_synchronous_mqtt_connection_handler.dart';
part 'src/connectionhandling/mqtt_client_mqtt_connection.dart';

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
    if (connectionHandler != null) {
      connectionHandler.websocketProtocols = protocols;
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
    if (username != null) {
      MqttLogger.log("Authenticating with username '{$username}' "
          "and password '{$password}'");
      if (username.trim().length >
          Constants.recommendedMaxUsernamePasswordLength) {
        MqttLogger.log('Username length (${username.trim().length}) '
            'exceeds the max recommended in the MQTT spec. ');
      }
    }
    if (password != null &&
        password.trim().length >
            Constants.recommendedMaxUsernamePasswordLength) {
      MqttLogger.log('Password length (${password.trim().length}) '
          'exceeds the max recommended in the MQTT spec. ');
    }
    // Set the authentication parameters in the connection
    // message if we have one.
    connectionMessage?.authenticateAs(username, password);

    // Do the connection
    clientEventBus = events.EventBus();
    connectionHandler = SynchronousMqttConnectionHandler(clientEventBus);
    if (useWebSocket) {
      connectionHandler.secure = false;
      connectionHandler.useWebSocket = true;
      connectionHandler.useAlternateWebSocketImplementation =
          useAlternateWebSocketImplementation;
      if (_websocketProtocols != null) {
        connectionHandler.websocketProtocols = _websocketProtocols;
      }
    }
    if (secure) {
      connectionHandler.secure = true;
      connectionHandler.useWebSocket = false;
      connectionHandler.useAlternateWebSocketImplementation = false;
      connectionHandler.securityContext = securityContext;
      connectionHandler.onBadCertificate = onBadCertificate;
    }
    connectionHandler.onDisconnected = internalDisconnect;
    connectionHandler.onConnected = onConnected;
    publishingManager = PublishingManager(connectionHandler, clientEventBus);
    subscriptionsManager = SubscriptionsManager(
        connectionHandler, publishingManager, clientEventBus);
    subscriptionsManager.onSubscribed = onSubscribed;
    subscriptionsManager.onUnsubscribed = onUnsubscribed;
    subscriptionsManager.onSubscribeFail = onSubscribeFail;
    updates = subscriptionsManager.subscriptionNotifier.changes;
    keepAlive = MqttConnectionKeepAlive(connectionHandler, keepAlivePeriod);
    if (pongCallback != null) {
      keepAlive.pongCallback = pongCallback;
    }
    final connectMessage = getConnectMessage(username, password);
    return connectionHandler.connect(server, port, connectMessage);
  }

}
