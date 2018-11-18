/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 30/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Subscribed and Unsubscribed callback typedefs
typedef SubscribeCallback = void Function(String topic);
typedef UnsubscribeCallback = void Function(String topic);

/// A class that can manage the topic subscription process.
class SubscriptionsManager {
  ///  Creates a new instance of a SubscriptionsManager that uses the specified connection to manage subscriptions.
  SubscriptionsManager(
      this.connectionHandler, this.publishingManager, this._clientEventBus) {
    connectionHandler.registerForMessage(
        MqttMessageType.subscribeAck, confirmSubscription);
    connectionHandler.registerForMessage(
        MqttMessageType.unsubscribeAck, confirmUnsubscribe);
    // Start listening for published messages
    _clientEventBus.on<MessageReceived>().listen(publishMessageReceived);
  }

  /// Dispenser used for keeping track of subscription ids
  MessageIdentifierDispenser messageIdentifierDispenser =
      MessageIdentifierDispenser();

  /// List of confirmed subscriptions, keyed on the topic name.
  Map<String, Subscription> subscriptions = Map<String, Subscription>();

  /// A list of subscriptions that are pending acknowledgement, keyed on the message identifier.
  Map<int, Subscription> pendingSubscriptions = Map<int, Subscription>();

  /// The connection handler that we use to subscribe to subscription acknowledgements.
  IMqttConnectionHandler connectionHandler;

  /// Publishing manager used for passing on published messages to subscribers.
  PublishingManager publishingManager;

  /// Subscribe and Unsubscribe callbacks
  SubscribeCallback onSubscribed;

  /// Unsubscribed
  UnsubscribeCallback onUnsubscribed;

  /// The event bus
  events.EventBus _clientEventBus;

  /// Observable change notifier for all subscribed topics
  final observe.ChangeNotifier<MqttReceivedMessage<MqttMessage>>
      _subscriptionNotifier =
      observe.ChangeNotifier<MqttReceivedMessage<MqttMessage>>();

  /// Subscription notifier
  observe.ChangeNotifier<MqttReceivedMessage<MqttMessage>>
      get subscriptionNotifier => _subscriptionNotifier;

  /// Registers a new subscription with the subscription manager.
  Subscription registerSubscription(String topic, MqttQos qos) {
    Subscription cn = tryGetExistingSubscription(topic);
    return cn ??= createNewSubscription(topic, qos);
  }

  /// Gets a view on the existing observable, if the subscription already exists.
  Subscription tryGetExistingSubscription(String topic) {
    final Subscription retSub = subscriptions[topic];
    if (retSub == null) {
      // Search the pending subscriptions
      for (Subscription sub in pendingSubscriptions.values) {
        if (sub.topic.rawTopic == topic) {
          return sub;
        }
      }
    }
    return retSub;
  }

  /// Creates a new subscription for the specified topic.
  Subscription createNewSubscription(String topic, MqttQos qos) {
    try {
      final SubscriptionTopic subscriptionTopic = SubscriptionTopic(topic);
      // Get an ID that represents the subscription. We will use this same ID for unsubscribe as well.
      final int msgId = messageIdentifierDispenser.getNextMessageIdentifier();
      final Subscription sub = Subscription();
      sub.topic = subscriptionTopic;
      sub.qos = qos;
      sub.messageIdentifier = msgId;
      sub.createdTime = DateTime.now();
      pendingSubscriptions[sub.messageIdentifier] = sub;
      // Build a subscribe message for the caller and send it off to the broker.
      final MqttSubscribeMessage msg = MqttSubscribeMessage()
          .withMessageIdentifier(sub.messageIdentifier)
          .toTopic(sub.topic.rawTopic)
          .atQos(sub.qos);
      connectionHandler.sendMessage(msg);
      return sub;
    } on Exception {
      throw InvalidTopicException(
          'from SubscriptionManager::createNewSubscription', topic);
    }
  }

  /// Publish message received
  void publishMessageReceived(MessageReceived event) {
    final PublicationTopic topic = event.topic;
    final MqttReceivedMessage<MqttMessage> msg =
        MqttReceivedMessage<MqttMessage>(topic.rawTopic, event.message);
    subscriptionNotifier.notifyChange(msg);
  }

  /// Unsubscribe from a topic
  void unsubscribe(String topic) {
    final MqttUnsubscribeMessage unsubscribeMsg = MqttUnsubscribeMessage()
        .withMessageIdentifier(
            messageIdentifierDispenser.getNextMessageIdentifier())
        .fromTopic(topic);
    connectionHandler.sendMessage(unsubscribeMsg);
  }

  /// Confirms a subscription has been made with the broker. Marks the sub as confirmed in the subs storage.
  /// Returns true, always.
  bool confirmSubscription(MqttMessage msg) {
    final MqttSubscribeAckMessage subAck = msg;
    String topic;
    if (pendingSubscriptions
        .containsKey(subAck.variableHeader.messageIdentifier)) {
      topic = pendingSubscriptions[subAck.variableHeader.messageIdentifier]
          .topic
          .rawTopic;
      subscriptions[topic] =
          pendingSubscriptions[subAck.variableHeader.messageIdentifier];
      pendingSubscriptions.remove(subAck.variableHeader.messageIdentifier);
    }
    if (onSubscribed != null) {
      onSubscribed(topic);
    }
    return true;
  }

  /// Cleans up after an unsubscribe message is received from the broker.
  /// returns true, always
  bool confirmUnsubscribe(MqttMessage msg) {
    final MqttUnsubscribeAckMessage unSubAck = msg;
    String subKey;
    Subscription sub;
    subscriptions.forEach((String key, Subscription value) {
      if (value.messageIdentifier ==
          unSubAck.variableHeader.messageIdentifier) {
        sub = value;
        subKey = key;
      }
    });
    // If we have the subscription remove it
    if (sub != null) {
      if (onUnsubscribed != null) {
        onUnsubscribed(subKey);
      }
      subscriptions.remove(subKey);
    }
    return true;
  }

  /// Gets the current status of a subscription.
  SubscriptionStatus getSubscriptionsStatus(String topic) {
    SubscriptionStatus status = SubscriptionStatus.doesNotExist;
    if (subscriptions.containsKey(topic)) {
      status = SubscriptionStatus.active;
    }
    pendingSubscriptions.forEach((int key, Subscription value) {
      if (value.topic.rawTopic == topic) {
        status = SubscriptionStatus.pending;
      }
    });
    return status;
  }
}
