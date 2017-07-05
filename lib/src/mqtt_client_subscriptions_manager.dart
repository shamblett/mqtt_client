/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 30/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// A class that can manage the topic subscription process.
class SubscriptionsManager extends events.EventDetector {
  /// Dispenser used for keeping track of subscription ids
  MessageIdentifierDispenser messageIdentifierDispenser =
  new MessageIdentifierDispenser();

  /// List of confirmed subscriptions, keyed on the topic name.
  Map<String, Subscription> subscriptions = new Map<String, Subscription>();

  /// A list of subscriptions that are pending acknowledgement, keyed on the message identifier.
  Map<int, Subscription> pendingSubscriptions = new Map<int, Subscription>();

  /// The connection handler that we use to subscribe to subscription acknowledgements.
  IMqttConnectionHandler connectionHandler;

  /// Publishing manager used for passing on published messages to subscribers.
  PublishingManager publishingManager;

  /// Observable publish messages received map, indexed by topic
  Map<String, ChangeNotifier<MqttReceivedMessage>> messagesReceived =
  new Map<String, ChangeNotifier<MqttReceivedMessage>>();

  ///  Creates a new instance of a SubscriptionsManager that uses the specified connection to manage subscriptions.
  SubscriptionsManager(IMqttConnectionHandler connectionHandler,
      IPublishingManager publishingManager) {
    this.connectionHandler = connectionHandler;
    this.publishingManager = publishingManager;
    this
        .connectionHandler
        .registerForMessage(MqttMessageType.subscribeAck, confirmSubscription);
    this
        .connectionHandler
        .registerForMessage(MqttMessageType.unsubscribeAck, confirmUnsubscribe);
    // Start listening for published messages
    this.listen(
        this.publishingManager, MessageReceived, publishMessageReceived);
  }

  /// Registers a new subscription with the subscription manager.
  ChangeNotifier<MqttReceivedMessage> registerSubscription(String topic,
      MqttQos qos) {
    ChangeNotifier<MqttReceivedMessage> cn = tryGetExistingSubscription(topic);
    if (cn == null) {
      cn = createNewSubscription(topic, qos);
    }
    return cn;
  }

  /// Gets a view on the existing observable, if the subscription already exists.
  ChangeNotifier<MqttReceivedMessage> tryGetExistingSubscription(String topic) {
    Subscription retSub = subscriptions[topic];
    if (retSub == null) {
      // Search the pending subscriptions
      for (Subscription sub in pendingSubscriptions.values) {
        if (sub.topic.rawTopic == topic) {
          retSub = sub;
        }
      }
    }
    return retSub != null ? retSub.observable : null;
  }

  /// Creates a new subscription for the specified topic.
  ChangeNotifier<MqttReceivedMessage> createNewSubscription(String topic,
      MqttQos qos) {
    try {
      final SubscriptionTopic subscriptionTopic = new SubscriptionTopic(topic);
      // Get an ID that represents the subscription. We will use this same ID for unsubscribe as well.
      final int msgId =
      messageIdentifierDispenser.getNextMessageIdentifier("subscriptions");
      // Create a new observable that is used to yield messages
      // that arrive for the topic.
      final ChangeNotifier<MqttReceivedMessage> observable =
      createObservableForSubscription(subscriptionTopic, msgId);
      final Subscription sub = new Subscription();
      sub.topic = subscriptionTopic;
      sub.qos = qos;
      sub.messageIdentifier = msgId;
      sub.createdTime = new DateTime.now();
      sub.observable = observable;
      pendingSubscriptions[sub.messageIdentifier] = sub;
      // Build a subscribe message for the caller and send it off to the broker.
      final MqttSubscribeMessage msg = new MqttSubscribeMessage()
          .withMessageIdentifier(sub.messageIdentifier)
          .toTopic(sub.topic.rawTopic)
          .atQos(sub.qos);
      connectionHandler.sendMessage(msg);
      return sub.observable;
    } catch (Exception) {
      throw new InvalidTopicException(
          "from SubscriptionManager::createNewSubscription", topic);
    }
  }

  /// Publish message received
  void publishMessageReceived(events.Event<MessageReceived> event) {
    final String topic = event.data.topic.rawTopic;
    if (messagesReceived.containsKey(topic)) {
      final MqttReceivedMessage<MqttMessage> msg =
      new MqttReceivedMessage<MqttMessage>(topic, event.data.message);
      messagesReceived[topic].notifyChange(msg);
    }
  }

  /// Creates an observable for a subscription.
  ChangeNotifier<MqttReceivedMessage> createObservableForSubscription(
      SubscriptionTopic subscriptionTopic, int msgId) {
    final String topic = subscriptionTopic.rawTopic;
    final ChangeNotifier<MqttReceivedMessage> cn =
    new ChangeNotifier<MqttReceivedMessage>();
    messagesReceived[topic] = cn;
    return cn;
  }

  /// Confirms a subscription has been made with the broker. Marks the sub as confirmed in the subs storage.
  /// Returns true, always.
  bool confirmSubscription(MqttMessage msg) {
    return true;
  }

  /// Cleans up after an unsubscribe message is received from the broker.
  /// returns true, always
  bool confirmUnsubscribe(MqttMessage msg) {
    return true;
  }
}
