/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/07/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// A client class for interacting with MQTT Data Packets
class MqttClient {
  /// Initializes a new instance of the MqttClient class using the default Mqtt Port.
  /// The server hostname to connect to
  /// The client identifier to use to connect with
  MqttClient(this.server, this.clientIdentifier) {
    this.port = Constants.defaultMqttPort;
  }

  /// Initializes a new instance of the MqttClient class using the supplied Mqtt Port.
  /// The server hostname to connect to
  /// The client identifier to use to connect with
  /// The port to use
  MqttClient.withPort(this.server, this.clientIdentifier, this.port);

  String server;
  int port;
  String clientIdentifier;

  /// The Handler that is managing the connection to the remote server.
  MqttConnectionHandler _connectionHandler;

  /// The subscriptions manager responsible for tracking subscriptions.
  SubscriptionsManager _subscriptionsManager;

  /// Handles the connection management while idle.
  MqttConnectionKeepAlive _keepAlive;

  /// Handles everything to do with publication management.
  PublishingManager _publishingManager;

  /// Gets the current conneciton state of the Mqtt Client.
  ConnectionState get connectionState =>
      _connectionHandler != null
          ? _connectionHandler.connectionState
          : ConnectionState.disconnected;

  /// The connection message to use to override the default
  MqttConnectMessage _connectionMessage;

  /// Performs a synchronous connect to the message broker with an optional username and password
  /// for the purposes of authentication.
  Future<ConnectionState> connect([String username, String password]) async {
    if (username != null) {
      print(
          "Authenticating with username '{$username}' and password '{$password}'");
      if (username
          .trim()
          .length >
          Constants.recommendedMaxUsernamePasswordLength) {
        print("Username length (${username
                .trim()
                .length}) exceeds the max recommended in the MQTT spec. ");
      }
    }
    if (password != null &&
        password
            .trim()
            .length >
            Constants.recommendedMaxUsernamePasswordLength) {
      print("Password length (${ password
              .trim()
              .length}) exceeds the max recommended in the MQTT spec. ");
    }
    _connectionHandler = new SynchronousMqttConnectionHandler();
    _publishingManager = new PublishingManager(_connectionHandler);
    _subscriptionsManager =
    new SubscriptionsManager(_connectionHandler, _publishingManager);
    _keepAlive = new MqttConnectionKeepAlive(
        _connectionHandler, Constants.defaultKeepAlive);
    final connectMessage = _getConnectMessage(username, password);
    return await _connectionHandler.connect(
        this.server, this.port, connectMessage);
  }

  ///  Gets a pre-configured connect message if one has not been supplied by the user.
  ///  Returns an MqttConnectMessage that can be used to connect to a message broker
  MqttConnectMessage _getConnectMessage(String username, String password) {
    if (_connectionMessage == null) {
      _connectionMessage = new MqttConnectMessage()
          .withClientIdentifier(clientIdentifier)
          .keepAliveFor(Constants.defaultKeepAlive)
          .authenticateAs(username, password)
          .startClean();
    }
    return _connectionMessage;
  }

  /// Initiates a topic subscription request to the connected broker with a strongly typed data processor callback.
  /// The topic to subscribe to.
  /// The qos level the message was published at.
  /// Returns the change notifier assigned to the subscription.
  /// Raises InvalidTopicException If a topic that does not meet the MQTT topic spec rules is provided.
  ChangeNotifier<MqttReceivedMessage> listenTo(String topic, MqttQos qosLevel) {
    if (_connectionHandler.connectionState != ConnectionState.connected) {
      throw new ConnectionException(_connectionHandler.connectionState);
    }
    return _subscriptionsManager.registerSubscription(topic, qosLevel);
  }

  /// Publishes a message to the message broker.
  /// Returns The message identifer assigned to the message.
  /// Raises InvalidTopicException if the topic supplied violates the MQTT topic format rules.
  int publishMessage(String topic, MqttQos qualityOfService,
      typed.Uint8Buffer data) {
    if (_connectionHandler.connectionState != ConnectionState.connected) {
      throw new ConnectionException(_connectionHandler.connectionState);
    }
    try {
      final PublicationTopic pubTopic = new PublicationTopic(topic);
      return _publishingManager.publish(pubTopic, qualityOfService, data);
    } catch (Exception) {
      throw new InvalidTopicException(Exception.toString(), topic);
    }
  }

  /// Unsubscribe from a topic
  void unsubscribe(String topic) {
    _subscriptionsManager.unsubscribe(topic);
  }

  /// Gets the current status of a subscription.
  SubscriptionStatus getSubscriptionsStatus(String topic) {
    return _subscriptionsManager.getSubscriptionsStatus(topic);
  }

  /// Disconnect from the broker
  void disconnect() {
    _connectionHandler.disconnect();
    _publishingManager = null;
    _subscriptionsManager = null;
    _keepAlive.stop();
    _keepAlive = null;
    _connectionHandler = null;
  }

  /// Turn on logging, true to start, false to stop
  void logging(bool on) {
    MqttLogger.loggingOn = false;
    if (on) {
      MqttLogger.loggingOn = true;
    }
  }
}
