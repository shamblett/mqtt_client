/*
 * Package : mqtt_browser_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/01/2020
 * Copyright :  S.Hamblett
 */

part of '../mqtt_browser_client.dart';

class MqttBrowserClient extends MqttClient {
  /// Initializes a new instance of the MqttServerClient class using the
  /// default Mqtt Port.
  /// The server hostname or URL to connect to
  /// The client identifier to use to connect with
  MqttBrowserClient(
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
  MqttBrowserClient.withPort(
    super.server,
    super.clientIdentifier,
    super.port, {
    this.maxConnectionAttempts =
        MqttClientConstants.defaultMaxConnectionAttempts,
  }) : super.withPort();

  /// Max connection attempts
  final int maxConnectionAttempts;

  /// Performs a connect to the message broker with an optional
  /// username and password for the purposes of authentication.
  /// If a username and password are supplied these will override
  /// any previously set in a supplied connection message so if you
  /// supply your own connection message and use the authenticateAs method to
  /// set these parameters do not set them again here.
  @override
  Future<MqttClientConnectionStatus?> connect(
      [String? username, String? password]) async {
    instantiationCorrect = true;
    clientEventBus = events.EventBus();
    clientEventBus
        ?.on<DisconnectOnNoPingResponse>()
        .listen(disconnectOnNoPingResponse);
    clientEventBus
        ?.on<DisconnectOnNoMessageSent>()
        .listen(disconnectOnNoMessageSent);
    connectionHandler = SynchronousMqttBrowserConnectionHandler(clientEventBus,
        maxConnectionAttempts: maxConnectionAttempts,
        reconnectTimePeriod: connectTimeoutPeriod);
    return await super.connect(username, password);
  }
}
