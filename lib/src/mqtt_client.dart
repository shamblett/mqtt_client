// ignore_for_file: member-ordering

/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/07/2017
 * Copyright :  S.Hamblett
 */

part of '../mqtt_client.dart';

/// The client disconnect callback type
typedef DisconnectCallback = void Function();

/// The client Connect callback type
typedef ConnectCallback = void Function();

/// The client auto reconnect callback type
typedef AutoReconnectCallback = void Function();

/// The client auto reconnect complete callback type
typedef AutoReconnectCompleteCallback = void Function();

/// The client failed connection attempt callback
typedef FailedConnectionAttemptCallback = void Function(int attemptNumber);

/// A client class for interacting with MQTT Data Packets.
/// Do not instantiate this class directly, instead instantiate
/// either a [MqttClientServer] class or an [MqttBrowserClient] as needed.
/// This class now provides common functionality between server side
/// and web based clients.
class MqttClient {
  /// Server name.
  /// Note that a server name that is a host name must conform to the name
  /// syntax described in RFC952 [https://datatracker.ietf.org/doc/html/rfc952]
  String server;

  /// Port number
  int port = 1883;

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

  /// Socket timeout period.
  ///
  /// Specifies the maximum time in milliseconds a connect call will wait for socket connection.
  ///
  /// Can be used to stop excessive waiting time at the network layer.
  /// For TCP sockets only, not websockets.
  ///
  /// Note this takes precedence over [connectTimeoutPeriod], if this is set
  /// [connectTimeoutPeriod] will be disabled.
  ///
  /// Minimum value is 1000ms.
  int? _socketTimeout;
  int? get socketTimeout => _socketTimeout;
  set socketTimeout(int? period) {
    if (period != null && period >= 1000) {
      _socketTimeout = period;
      _connectTimeoutPeriod = 10;
    }
  }

  /// Connect timeout value in milliseconds, i.e the time period between
  /// successive connection attempts.
  ///
  /// Minimum value is 1000ms, defaults to 5000ms.
  ///
  /// if [socketTimeout] is set then its value will take precedence so this will only
  /// apply if you do not set [socketTimeout]. If you do then this value will be set to 10ms
  /// which effectively disables it.
  int _connectTimeoutPeriod = 5000;
  int get connectTimeoutPeriod => _connectTimeoutPeriod;
  set connectTimeoutPeriod(int period) {
    if (_socketTimeout == null) {
      int periodToSet = period;
      if (period < 1000) {
        periodToSet = 5000;
      }
      _connectTimeoutPeriod = periodToSet;
    }
  }

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
  MqttConnectionHandlerBase? connectionHandler;

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

    final connectionHandler = this.connectionHandler;
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
      publishingManager?.published.stream;

  /// Gets the current connection state of the Mqtt Client.
  /// Will be removed, use connectionStatus
  @Deprecated('Use ConnectionStatus, not this')
  MqttConnectionState? get connectionState => connectionHandler != null
      ? connectionHandler!.connectionStatus.state
      : MqttConnectionState.disconnected;

  final MqttClientConnectionStatus _connectionStatus =
      MqttClientConnectionStatus();

  /// Gets the current connection status of the Mqtt Client.
  /// This is the connection state as above also with the broker return code.
  /// Set after every connection attempt.
  MqttClientConnectionStatus? get connectionStatus => connectionHandler != null
      ? connectionHandler!.connectionStatus
      : _connectionStatus;

  /// The connection message to use to override the default.
  MqttConnectMessage? _connectionMessage;
  MqttConnectMessage? get connectionMessage => _connectionMessage;
  set connectionMessage(MqttConnectMessage? connMessage) {
    _connectionMessage = connMessage;
    _connectionMessage?.variableHeader?.protocolVersion = Protocol.version;
    _connectionMessage?.variableHeader?.protocolName = Protocol.name;
  }

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

  /// Failed Connection attempt callback.
  /// Called on every failed connection attempt, if [maxConnectionAttempts] is
  /// set to 5 say this will be called 5 times if the connection fails,
  /// one for every failed attempt. Note this is never called
  /// if [autoReconnect] is set, also the [NoConnectionException] is not raised
  /// if this callback is supplied.
  FailedConnectionAttemptCallback? onFailedConnectionAttempt;

  /// On subscribed.
  /// Called for each single subscription request on reception of
  /// the associated subscription acknowledge message.
  /// Called only once for a batch subscription request, the topic will be
  /// set to the first topic of the request.
  SubscribeCallback? _onSubscribed;
  SubscribeCallback? get onSubscribed => _onSubscribed;

  set onSubscribed(SubscribeCallback? cb) {
    _onSubscribed = cb;
    subscriptionsManager?.onSubscribed = cb;
  }

  /// On subscribe fail.
  /// Invoked by subscribe if an invalid topic is supplied or on
  /// reception of a failed subscribe indication from the broker.
  /// For batch subscriptions this is only invoked if all subscriptions in
  /// the batch fail.
  SubscribeFailCallback? _onSubscribeFail;
  SubscribeFailCallback? get onSubscribeFail => _onSubscribeFail;

  set onSubscribeFail(SubscribeFailCallback? cb) {
    _onSubscribeFail = cb;
    subscriptionsManager?.onSubscribeFail = cb;
  }

  /// Unsubscribed callback, function returns a void and takes a
  /// string parameter, the topic that has been unsubscribed.
  UnsubscribeCallback? _onUnsubscribed;
  UnsubscribeCallback? get onUnsubscribed => _onUnsubscribed;

  set onUnsubscribed(UnsubscribeCallback? cb) {
    _onUnsubscribed = cb;
    subscriptionsManager?.onUnsubscribed = cb;
  }

  /// Ping response(pong) received callback.
  /// If set when a ping response is received from the broker
  /// this will be called.
  /// Can be used for health monitoring outside of the client itself.
  PongCallback? _pongCallback;
  PongCallback? get pongCallback => _pongCallback;

  set pongCallback(PongCallback? cb) {
    _pongCallback = cb;
    keepAlive?.pongCallback = cb;
  }

  /// Ping request(ping) sent callback.
  /// If set when a ping request is sent from the client
  /// this will be called.
  /// Can be used in tandem with the [pongCallback] for latency calculations.
  PingCallback? _pingCallback;
  PingCallback? get pingCallback => _pingCallback;

  set pingCallback(PingCallback? cb) {
    _pingCallback = cb;
    keepAlive?.pingCallback = cb;
  }

  /// The latency of the last ping/pong cycle in milliseconds.
  /// Cleared on disconnect.
  int? get lastCycleLatency => keepAlive?.lastCycleLatency;

  /// The average latency of all ping/pong cycles in a connection period in
  /// milliseconds. Cleared on disconnect.
  int? get averageCycleLatency => keepAlive?.averageCycleLatency;

  /// The event bus
  @protected
  events.EventBus? clientEventBus;

  /// The stream on which all subscribed topic updates are published to
  Stream<List<MqttReceivedMessage<MqttMessage>>>? get updates =>
      subscriptionsManager?.subscriptionNotifier;

  /// Common client connection method.
  Future<MqttClientConnectionStatus?> connect([
    String? username,
    String? password,
  ]) async {
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
    final connectionHandler = this.connectionHandler;
    if (connectionHandler == null) {
      throw StateError('connectionHandler is null');
    }
    if (websocketProtocolString != null) {
      connectionHandler.websocketProtocols = websocketProtocolString;
    }
    connectionHandler.onDisconnected = internalDisconnect;
    connectionHandler.onConnected = onConnected;
    connectionHandler.onAutoReconnect = onAutoReconnect;
    connectionHandler.onAutoReconnected = onAutoReconnected;
    connectionHandler.onFailedConnectionAttempt = onFailedConnectionAttempt;

    MqttLogger.log(
      'MqttClient::connect - Connection timeout period is $connectTimeoutPeriod milliseconds',
    );
    publishingManager = PublishingManager(connectionHandler, clientEventBus);
    publishingManager!.manuallyAcknowledgeQos1 = _manuallyAcknowledgeQos1;
    subscriptionsManager = SubscriptionsManager(
      connectionHandler,
      publishingManager,
      clientEventBus,
    );
    subscriptionsManager!.onSubscribed = onSubscribed;
    subscriptionsManager!.onUnsubscribed = onUnsubscribed;
    subscriptionsManager!.onSubscribeFail = onSubscribeFail;
    subscriptionsManager!.resubscribeOnAutoReconnect =
        resubscribeOnAutoReconnect;
    if (keepAlivePeriod != MqttClientConstants.defaultKeepAlive) {
      MqttLogger.log(
        'MqttClient::connect - keep alive is enabled with a value of $keepAlivePeriod seconds',
      );
      keepAlive = MqttConnectionKeepAlive(
        connectionHandler,
        clientEventBus,
        keepAlivePeriod,
        disconnectOnNoResponsePeriod,
      );
      if (pongCallback != null) {
        keepAlive!.pongCallback = pongCallback;
      }
      if (pingCallback != null) {
        keepAlive!.pingCallback = pingCallback;
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
        'MqttClient::doAutoReconnect - auto reconnect is not set, exiting',
      );
      return;
    }

    if (connectionStatus!.state != MqttConnectionState.connected || force) {
      // Fire a manual auto reconnect request.
      final wasConnected =
          connectionStatus!.state == MqttConnectionState.connected;
      clientEventBus!.fire(
        AutoReconnect(userRequested: true, wasConnected: wasConnected),
      );
    }
  }

  /// Initiates a topic subscription request to the broker.
  /// The topic to subscribe to.
  /// The qos level the message was published at.
  /// Returns the subscription or null on failure.
  Subscription? subscribe(String topic, MqttQos qosLevel) {
    if (connectionStatus!.state != MqttConnectionState.connected) {
      throw ConnectionException(connectionHandler?.connectionStatus.state);
    }
    return subscriptionsManager!.registerSubscription(topic, qosLevel);
  }

  /// Initiates a batch subscription request to the broker.
  /// This sends multiple subscription requests to the broker in a single
  /// subscription message. The returned [Subscription] allows the tracking
  /// of the status of the individual subscriptions.
  /// Returns the subscription or null on failure.
  Subscription? subscribeBatch(List<BatchSubscription> subscriptions) {
    if (connectionStatus!.state != MqttConnectionState.connected) {
      throw ConnectionException(connectionHandler?.connectionStatus.state);
    }
    return subscriptions.isEmpty
        ? null
        : subscriptionsManager!.registerBatchSubscription(subscriptions);
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
  /// Returns The message identifier assigned to the message.
  /// Raises InvalidTopicException if the topic supplied violates the
  /// MQTT topic format rules.
  int publishMessage(
    String topic,
    MqttQos qualityOfService,
    typed.Uint8Buffer data, {
    bool retain = false,
  }) {
    if (connectionHandler?.connectionStatus.state !=
        MqttConnectionState.connected) {
      throw ConnectionException(connectionHandler?.connectionStatus.state);
    }
    try {
      final pubTopic = PublicationTopic(topic);
      return publishingManager!.publish(
        pubTopic,
        qualityOfService,
        data,
        retain,
      );
    } on Exception catch (e, stack) {
      Error.throwWithStackTrace(
        InvalidTopicException(e.toString(), topic),
        stack,
      );
    }
  }

  /// Unsubscribe from a topic.
  /// Some brokers(AWS for instance) need to have each un subscription acknowledged, use
  /// the [expectAcknowledge] parameter for this, default is false.
  /// For a batch subscription provide the topic of the first subscription
  /// in the batch.
  void unsubscribe(String topic, {expectAcknowledge = false}) {
    subscriptionsManager!.unsubscribe(
      topic,
      expectAcknowledge: expectAcknowledge,
    );
  }

  /// Gets the current status of a subscription.
  ///
  /// A batch subscription contains the status of each subscribed topic as returned
  /// by the broker only if the status is active.
  ///
  /// A status of [MqttSubscriptionStatus.doesNotExist] is returned if a single subscription fails
  /// or all the subscriptions in a batch subscription fail.
  MqttSubscriptionStatus getSubscriptionsStatus(String topic) =>
      subscriptionsManager!.getSubscriptionsStatus(topic);

  /// Gets the current status of a subscription using its
  /// returned [Subscription].
  ///
  /// Functionally equivalent to [getSubscriptionsStatus].
  MqttSubscriptionStatus getSubscriptionsStatusBySubscription(
    Subscription sub,
  ) => subscriptionsManager!.getSubscriptionsStatusBySubscription(sub);

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
      'MqttClient::_disconnectOnNoPingResponse - disconnecting, no ping request response for $disconnectOnNoResponsePeriod seconds',
    );
    // Destroy the existing client socket
    connectionHandler?.connection.disconnect();
    internalDisconnect();
  }

  /// Called when the send message function throws exception
  /// a ping response expected from the broker has not arrived in the
  /// time period specified by [disconnectOnNoResponsePeriod].
  void disconnectOnNoMessageSent(DisconnectOnNoMessageSent event) {
    MqttLogger.log(
      'MqttClient::disconnectOnNoMessageSent - disconnecting, no message sent due to exception like socket exception',
    );
    // Destroy the existing client socket
    connectionHandler?.connection.disconnect();
    internalDisconnect();
  }

  /// Internal disconnect
  /// This is always passed to the connection handler to allow the
  /// client to close itself down correctly on disconnect.
  @protected
  void internalDisconnect() {
    // if we don't have a connection Handler we are already disconnected.
    final connectionHandler = this.connectionHandler;
    if (connectionHandler == null) {
      MqttLogger.log(
        'MqttClient::internalDisconnect - not invoking disconnect, no connection handler',
      );
      return;
    }
    if (autoReconnect && connectionHandler.initialConnectionComplete) {
      if (!connectionHandler.autoReconnectInProgress) {
        // Fire an automatic auto reconnect request
        clientEventBus!.fire(AutoReconnect(userRequested: false));
      } else {
        MqttLogger.log(
          'MqttClient::internalDisconnect - not invoking auto connect, already in progress',
        );
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
    subscriptionsManager?.closeSubscriptionNotifier();
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
  void checkCredentials(String? username, String? password) {
    if (username != null) {
      MqttLogger.log(
        "Authenticating with username '{$username}' "
        "and password '{$password}'",
      );
      if (Protocol.version == MqttClientConstants.mqttV31ProtocolVersion) {
        if (username.trim().length >
            MqttClientConstants.recommendedMaxUsernamePasswordLength) {
          MqttLogger.log(
            'MqttClient::checkCredentials - Advisory - Username length (${username.trim().length}) '
            'exceeds the max recommended in the MQTT 3.1 spec. ',
          );
        }
      }
    }

    if (password != null) {
      if (Protocol.version == MqttClientConstants.mqttV31ProtocolVersion) {
        if (password.trim().length >
            MqttClientConstants.recommendedMaxUsernamePasswordLength) {
          MqttLogger.log(
            'MqttClient::checkCredentials - Advisory - Password length (${password.trim().length}) '
            'exceeds the max recommended in the MQTT 3.1 spec. ',
          );
        }
      }
    }
  }

  /// Turn on logging, true to start, false to stop.
  /// Optionally disable publish message payload logging, defaults
  /// to log payloads, false disables this.
  void logging({required bool on, bool logPayloads = true}) {
    MqttLogger.loggingOn = false;
    if (on) {
      MqttLogger.loggingOn = true;
    }
    MqttLogger.logPayloads = logPayloads;
  }

  /// Set the protocol version to V3.1 - default
  void setProtocolV31() {
    Protocol.version = MqttClientConstants.mqttV31ProtocolVersion;
    Protocol.name = MqttClientConstants.mqttV31ProtocolName;
    connectionMessage?.withProtocolVersion(Protocol.version);
    connectionMessage?.withProtocolName(Protocol.name);
  }

  /// Set the protocol version to V3.1.1
  void setProtocolV311() {
    Protocol.version = MqttClientConstants.mqttV311ProtocolVersion;
    Protocol.name = MqttClientConstants.mqttV311ProtocolName;
    connectionMessage?.withProtocolVersion(Protocol.version);
    connectionMessage?.withProtocolName(Protocol.name);
  }
}
