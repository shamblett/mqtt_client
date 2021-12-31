/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/07/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// The client disconnect callback type
typedef DisconnectCallback = void Function();

/// The client Connect callback type
typedef ConnectCallback = void Function();

/// The client auto reconnect callback type
typedef AutoReconnectCallback = void Function();

/// The client auto reconnect complete callback type
typedef AutoReconnectCompleteCallback = void Function();

/// A client class for interacting with MQTT Data Packets.
/// Do not instantiate this class directly, instead instantiate
/// either a [MqttClientServer] class or an [MqttBrowserClient] as needed.
/// This class now provides common functionality between server side
/// and web based clients.
class MqttClient {
  /// Initializes a new instance of the MqttClient class using the
  /// default Mqtt Port.
  /// The server hostname to connect to
  /// The client identifier to use to connect with
  MqttClient(this.server, this.clientIdentifier) {
    port = MqttClientConstants.defaultMqttPort;
  }

  /// Initializes a new instance of the MqttClient class using
  /// the supplied Mqtt Port.
  /// The server/hostname to connect to.
  /// The client identifier to use to connect with.
  /// The port to use
  MqttClient.withPort(this.server, this.clientIdentifier, this.port);

  /// Server name.
  /// Note that a server name that is a host name must conform to the name
  /// syntax described in RFC952 [https://datatracker.ietf.org/doc/html/rfc952]
  String server;

  /// Port number
  int? port;

  /// Client identifier
  String clientIdentifier;

  /// Incorrect instantiation protection
  @protected
  var instantiationCorrect = false;

  /// Auto reconnect, the client will auto reconnect if set true.
  ///
  /// The auto reconnect mechanism will not be invoked either for a client
  /// that has not been connected, i.e. you must have established an initial
  /// connection to the broker or for a solicited disconnect request.
  ///
  /// Once invoked the mechanism will try forever to reconnect to the broker with its
  /// original connection parameters. This can be stopped only by calling
  /// [disconnect()] on the client.
  bool autoReconnect = false;

  /// Re subscribe on auto reconnect.
  /// Auto reconnect will perform automatic re subscription of existing confirmed subscriptions
  /// unless this is set to false.
  /// In this case the caller must perform their own re subscriptions manually using [unsubscribe],
  /// [subscribe] and [resubscribe] as needed from the appropriate callbacks.
  bool resubscribeOnAutoReconnect = true;

  /// Indicates that received QOS 1 messages(AtLeastOnce) are not to be automatically acknowledged by
  /// the client. The user must do this when the message has been taken off the update stream
  /// using the [acknowledgeQos1Message] method.
  bool _manuallyAcknowledgeQos1 = false;
  set manuallyAcknowledgeQos1(bool state) {
    publishingManager?.manuallyAcknowledgeQos1 = state;
    _manuallyAcknowledgeQos1 = state;
  }

  bool get manuallyAcknowledgeQos1 => _manuallyAcknowledgeQos1;

  /// Manually acknowledge a received QOS 1 message.
  /// Has no effect if [manuallyAcknowledgeQos1] is not in force
  /// or the message is not awaiting a QOS 1 acknowledge.
  /// Returns true if an acknowledgement is sent to the broker.
  bool? acknowledgeQos1Message(MqttPublishMessage message) =>
      publishingManager?.acknowledgeQos1Message(message);

  /// The number of QOS 1 messages awaiting manual acknowledge.
  int get messagesAwaitingManualAcknowledge => publishingManager == null
      ? 0
      : publishingManager!.awaitingManualAcknowledge.length;

  /// The Handler that is managing the connection to the remote server.
  @protected
  dynamic connectionHandler;

  @protected
  List<String>? websocketProtocolString;

  /// User definable websocket protocols. Use this for non default websocket
  /// protocols only if your broker needs this. There are two defaults in
  /// MqttWsConnection class, the multiple protocol is the default. Some brokers
  /// will not accept a list and only expect a single protocol identifier,
  /// in this case use the single protocol default. You can supply your own
  /// list, or to disable this entirely set the protocols to an
  /// empty list , i.e [].
  set websocketProtocols(List<String> protocols) {
    websocketProtocolString = protocols;
    if (connectionHandler != null) {
      connectionHandler.websocketProtocols = protocols;
    }
  }

  /// The subscriptions manager responsible for tracking subscriptions.
  @protected
  SubscriptionsManager? subscriptionsManager;

  /// Handles the connection management while idle.
  /// Not instantiated if keep alive is disabled.
  @protected
  MqttConnectionKeepAlive? keepAlive;

  /// Keep alive period, seconds.
  /// Keep alive is defaulted to off, this must be set to a valid value to
  /// enable keep alive.
  int keepAlivePeriod = MqttClientConstants.defaultKeepAlive;

  /// The period of time to wait if the broker does not respond to a ping request
  /// from keep alive processing, in seconds.
  /// If this time period is exceeded the client is forcibly disconnected.
  /// The default is 0, which disables this functionality.
  /// Thi setting has no effect if keep alive is disabled.
  int disconnectOnNoResponsePeriod = 0;

  /// Handles everything to do with publication management.
  @protected
  PublishingManager? publishingManager;

  /// Published message stream. A publish message is added to this
  /// stream on completion of the message publishing protocol for a Qos level.
  /// Attach listeners only after connect has been called.
  Stream<MqttPublishMessage>? get published =>
      publishingManager != null ? publishingManager!.published.stream : null;

  /// Gets the current connection state of the Mqtt Client.
  /// Will be removed, use connectionStatus
  @Deprecated('Use ConnectionStatus, not this')
  MqttConnectionState? get connectionState => connectionHandler != null
      ? connectionHandler.connectionStatus.state
      : MqttConnectionState.disconnected;

  final MqttClientConnectionStatus _connectionStatus =
      MqttClientConnectionStatus();

  /// Gets the current connection status of the Mqtt Client.
  /// This is the connection state as above also with the broker return code.
  /// Set after every connection attempt.
  MqttClientConnectionStatus? get connectionStatus => connectionHandler != null
      ? connectionHandler.connectionStatus
      : _connectionStatus;

  /// The connection message to use to override the default
  MqttConnectMessage? connectionMessage;

  /// Client disconnect callback, called on unsolicited disconnect.
  /// This will not be called even if set if [autoReconnect} is set,instead
  /// [AutoReconnectCallback] will be called.
  DisconnectCallback? onDisconnected;

  /// Client connect callback, called on successful connect
  ConnectCallback? onConnected;

  /// Auto reconnect callback, if auto reconnect is selected this callback will
  /// be called before auto reconnect processing is invoked to allow the user to
  /// perform any pre auto reconnect actions.
  AutoReconnectCallback? onAutoReconnect;

  /// Auto reconnected callback, if auto reconnect is selected this callback will
  /// be called after auto reconnect processing is completed to allow the user to
  /// perform any post auto reconnect actions.
  AutoReconnectCompleteCallback? onAutoReconnected;

  /// Subscribed callback, function returns a void and takes a
  /// string parameter, the topic that has been subscribed to.
  SubscribeCallback? _onSubscribed;

  /// On subscribed
  SubscribeCallback? get onSubscribed => _onSubscribed;

  set onSubscribed(SubscribeCallback? cb) {
    _onSubscribed = cb;
    subscriptionsManager?.onSubscribed = cb;
  }

  /// Subscribed failed callback, function returns a void and takes a
  /// string parameter, the topic that has failed subscription.
  /// Invoked either by subscribe if an invalid topic is supplied or on
  /// reception of a failed subscribe indication from the broker.
  SubscribeFailCallback? _onSubscribeFail;

  /// On subscribed fail
  SubscribeFailCallback? get onSubscribeFail => _onSubscribeFail;

  set onSubscribeFail(SubscribeFailCallback? cb) {
    _onSubscribeFail = cb;
    subscriptionsManager?.onSubscribeFail = cb;
  }

  /// Unsubscribed callback, function returns a void and takes a
  /// string parameter, the topic that has been unsubscribed.
  UnsubscribeCallback? _onUnsubscribed;

  /// On unsubscribed
  UnsubscribeCallback? get onUnsubscribed => _onUnsubscribed;

  set onUnsubscribed(UnsubscribeCallback? cb) {
    _onUnsubscribed = cb;
    subscriptionsManager?.onUnsubscribed = cb;
  }

  /// Ping response received callback.
  /// If set when a ping response is received from the broker
  /// this will be called.
  /// Can be used for health monitoring outside of the client itself.
  PongCallback? _pongCallback;

  /// The ping received callback
  PongCallback? get pongCallback => _pongCallback;

  set pongCallback(PongCallback? cb) {
    _pongCallback = cb;
    keepAlive?.pongCallback = cb;
  }

  /// The event bus
  @protected
  events.EventBus? clientEventBus;

  /// The stream on which all subscribed topic updates are published to
  Stream<List<MqttReceivedMessage<MqttMessage>>>? get updates =>
      subscriptionsManager?.subscriptionNotifier;

  /// Common client connection method.
  Future<MqttClientConnectionStatus?> connect(
      [String? username, String? password]) async {
    // Protect against an incorrect instantiation
    if (!instantiationCorrect) {
      throw IncorrectInstantiationException();
    }
    // Generate the client id for logging
    MqttLogger.clientId++;

    checkCredentials(username, password);
    // Set the authentication parameters in the connection
    // message if we have one.
    connectionMessage?.authenticateAs(username, password);

    // Do the connection
    if (websocketProtocolString != null) {
      connectionHandler.websocketProtocols = websocketProtocolString;
    }
    connectionHandler.onDisconnected = internalDisconnect;
    connectionHandler.onConnected = onConnected;
    connectionHandler.onAutoReconnect = onAutoReconnect;
    connectionHandler.onAutoReconnected = onAutoReconnected;

    publishingManager = PublishingManager(connectionHandler, clientEventBus);
    publishingManager!.manuallyAcknowledgeQos1 = _manuallyAcknowledgeQos1;
    subscriptionsManager = SubscriptionsManager(
        connectionHandler, publishingManager, clientEventBus);
    subscriptionsManager!.onSubscribed = onSubscribed;
    subscriptionsManager!.onUnsubscribed = onUnsubscribed;
    subscriptionsManager!.onSubscribeFail = onSubscribeFail;
    subscriptionsManager!.resubscribeOnAutoReconnect =
        resubscribeOnAutoReconnect;
    if (keepAlivePeriod != MqttClientConstants.defaultKeepAlive) {
      MqttLogger.log(
          'MqttClient::connect - keep alive is enabled with a value of $keepAlivePeriod seconds');
      keepAlive = MqttConnectionKeepAlive(connectionHandler, clientEventBus,
          keepAlivePeriod, disconnectOnNoResponsePeriod);
      if (pongCallback != null) {
        keepAlive!.pongCallback = pongCallback;
      }
    } else {
      MqttLogger.log('MqttClient::connect - keep alive is disabled');
    }
    final connectMessage = getConnectMessage(username, password);
    // If the client id is not set in the connection message use the one
    // supplied in the constructor.
    if (connectMessage.payload.clientIdentifier.isEmpty) {
      connectMessage.payload.clientIdentifier = clientIdentifier;
    }
    // Set keep alive period.
    connectMessage.variableHeader?.keepAlive = keepAlivePeriod;
    connectionMessage = connectMessage;
    return connectionHandler.connect(server, port, connectMessage);
  }

  ///  Gets a pre-configured connect message if one has not been
  ///  supplied by the user.
  ///  Returns an MqttConnectMessage that can be used to connect to a
  ///  message broker if the user has not set one.
  MqttConnectMessage getConnectMessage(String? username, String? password) =>
      connectionMessage ??= MqttConnectMessage()
          .withClientIdentifier(clientIdentifier)
          // Explicitly set the will flag
          .withWillQos(MqttQos.atMostOnce)
          .authenticateAs(username, password)
          .startClean();

  /// Auto reconnect method, used to invoke a manual auto reconnect sequence.
  /// If [autoReconnect] is not set this method does nothing.
  /// If the client is not disconnected this method will have no effect
  /// unless the [force] parameter is set to true, otherwise
  /// auto reconnect will try indefinitely to reconnect to the broker.
  void doAutoReconnect({bool force = false}) {
    if (!autoReconnect) {
      MqttLogger.log(
          'MqttClient::doAutoReconnect - auto reconnect is not set, exiting');
      return;
    }

    if (connectionStatus!.state != MqttConnectionState.connected || force) {
      // Fire a manual auto reconnect request.
      final wasConnected =
          connectionStatus!.state == MqttConnectionState.connected;
      clientEventBus!
          .fire(AutoReconnect(userRequested: true, wasConnected: wasConnected));
    }
  }

  /// Initiates a topic subscription request to the connected broker
  /// with a strongly typed data processor callback.
  /// The topic to subscribe to.
  /// The qos level the message was published at.
  /// Returns the subscription or null on failure
  Subscription? subscribe(String topic, MqttQos qosLevel) {
    if (connectionStatus!.state != MqttConnectionState.connected) {
      throw ConnectionException(connectionHandler?.connectionStatus?.state);
    }
    return subscriptionsManager!.registerSubscription(topic, qosLevel);
  }

  /// Re subscribe.
  /// Unsubscribes all confirmed subscriptions and re subscribes them
  /// without sending unsubscribe messages to the broker.
  /// If an unsubscribe message to the broker is needed then use
  /// [unsubscribe] followed by [subscribe] for each subscription.
  /// Can be used in auto reconnect processing to force manual re subscription of all existing
  /// confirmed subscriptions.
  void resubscribe() => subscriptionsManager!.resubscribe();

  /// Publishes a message to the message broker.
  /// Returns The message identifer assigned to the message.
  /// Raises InvalidTopicException if the topic supplied violates the
  /// MQTT topic format rules.
  int publishMessage(
      String topic, MqttQos qualityOfService, typed.Uint8Buffer data,
      {bool retain = false}) {
    if (connectionHandler?.connectionStatus?.state !=
        MqttConnectionState.connected) {
      throw ConnectionException(connectionHandler?.connectionStatus?.state);
    }
    try {
      final pubTopic = PublicationTopic(topic);
      return publishingManager!
          .publish(pubTopic, qualityOfService, data, retain);
    } on Exception catch (e) {
      throw InvalidTopicException(e.toString(), topic);
    }
  }

  /// Unsubscribe from a topic.
  /// Some brokers(AWS for instance) need to have each un subscription acknowledged, use
  /// the [expectAcknowledge] parameter for this, default is false.
  void unsubscribe(String topic, {expectAcknowledge = false}) {
    subscriptionsManager!
        .unsubscribe(topic, expectAcknowledge: expectAcknowledge);
  }

  /// Gets the current status of a subscription.
  MqttSubscriptionStatus getSubscriptionsStatus(String topic) =>
      subscriptionsManager!.getSubscriptionsStatus(topic);

  /// Disconnect from the broker.
  /// This is a hard disconnect, a disconnect message is sent to the
  /// broker and the client is then reset to its pre-connection state,
  /// i.e all subscriptions are deleted, on subsequent reconnection the
  /// use must re-subscribe, also the updates change notifier is re-initialised
  /// and as such the user must re-listen on this stream.
  ///
  /// Do NOT call this in any onDisconnect callback that may be set,
  /// this will result in a loop situation.
  ///
  /// This method will disconnect regardless of the [autoReconnect] state.
  void disconnect() {
    _disconnect(unsolicited: false);
  }

  /// Called when the keep alive mechanism has determined that
  /// a ping response expected from the broker has not arrived in the
  /// time period specified by [disconnectOnNoResponsePeriod].
  void disconnectOnNoPingResponse(DisconnectOnNoPingResponse event) {
    MqttLogger.log(
        'MqttClient::_disconnectOnNoPingResponse - disconnecting, no ping request response for $disconnectOnNoResponsePeriod seconds');
    // Destroy the existing client socket
    connectionHandler?.connection?.disconnect();
    internalDisconnect();
  }

  /// Internal disconnect
  /// This is always passed to the connection handler to allow the
  /// client to close itself down correctly on disconnect.
  @protected
  void internalDisconnect() {
    // if we don't have a connection Handler we are already disconnected.
    if (connectionHandler == null) {
      MqttLogger.log(
          'MqttClient::internalDisconnect - not invoking disconnect, no connection handler');
      return;
    }
    if (autoReconnect && connectionHandler.initialConnectionComplete) {
      if (!connectionHandler.autoReconnectInProgress) {
        // Fire an automatic auto reconnect request
        clientEventBus!.fire(AutoReconnect(userRequested: false));
      } else {
        MqttLogger.log(
            'MqttClient::internalDisconnect - not invoking auto connect, already in progress');
      }
    } else {
      // Unsolicited disconnect only if we are connected initially
      if (connectionHandler.initialConnectionComplete) {
        _disconnect(unsolicited: true);
      }
    }
  }

  /// Actual disconnect processing
  void _disconnect({bool unsolicited = true}) {
    // Only disconnect the connection handler if the request is
    // solicited, unsolicited requests, ie broker termination don't
    // need this.
    var disconnectOrigin = MqttDisconnectionOrigin.unsolicited;
    if (!unsolicited) {
      connectionHandler?.disconnect();
      disconnectOrigin = MqttDisconnectionOrigin.solicited;
      connectionHandler?.stopListening();
    }

    publishingManager?.published.close();
    publishingManager = null;
    subscriptionsManager = null;
    keepAlive?.stop();
    keepAlive = null;
    _connectionStatus.returnCode = connectionStatus?.returnCode;
    connectionHandler = null;
    clientEventBus?.destroy();
    clientEventBus = null;
    // Set the connection status before calling onDisconnected
    _connectionStatus.state = MqttConnectionState.disconnected;
    _connectionStatus.disconnectionOrigin = disconnectOrigin;
    if (onDisconnected != null) {
      onDisconnected!();
    }
  }

  /// Check the username and password validity
  @protected
  void checkCredentials(String? username, String? password) {
    if (username != null) {
      MqttLogger.log("Authenticating with username '{$username}' "
          "and password '{$password}'");
      if (username.trim().length >
          MqttClientConstants.recommendedMaxUsernamePasswordLength) {
        MqttLogger.log(
            'MqttClient::checkCredentials - Username length (${username.trim().length}) '
            'exceeds the max recommended in the MQTT spec. ');
      }
    }
    if (password != null &&
        password.trim().length >
            MqttClientConstants.recommendedMaxUsernamePasswordLength) {
      MqttLogger.log(
          'MqttClient::checkCredentials - Password length (${password.trim().length}) '
          'exceeds the max recommended in the MQTT spec. ');
    }
  }

  /// Turn on logging, true to start, false to stop
  void logging({required bool on}) {
    MqttLogger.loggingOn = false;
    if (on) {
      MqttLogger.loggingOn = true;
    }
  }

  /// Set the protocol version to V3.1 - default
  void setProtocolV31() {
    Protocol.version = MqttClientConstants.mqttV31ProtocolVersion;
    Protocol.name = MqttClientConstants.mqttV31ProtocolName;
  }

  /// Set the protocol version to V3.1.1
  void setProtocolV311() {
    Protocol.version = MqttClientConstants.mqttV311ProtocolVersion;
    Protocol.name = MqttClientConstants.mqttV311ProtocolName;
  }
}
