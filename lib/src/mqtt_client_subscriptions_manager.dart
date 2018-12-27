/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 30/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Subscribed and Unsubscribed callback typedefs
typedef SubscribeCallback = void Function(String topic);
typedef SubscribeFailCallback = void Function(String topic);
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

  /// A list of unsubscribe requests waiting for an unsubscribe ack message.
  /// Index is the message identifier of the unsubscribe message
  Map<int, String> pendingUnsubscriptions = Map<int, String>();

  /// The connection handler that we use to subscribe to subscription acknowledgements.
  IMqttConnectionHandler connectionHandler;

  /// Publishing manager used for passing on published messages to subscribers.
  PublishingManager publishingManager;

  /// Subscribe and Unsubscribe callbacks
  SubscribeCallback onSubscribed;

  /// Unsubscribed
  UnsubscribeCallback onUnsubscribed;

  /// Subscription failed callback
  SubscribeFailCallback onSubscribeFail;

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
  /// If the subscription cannot be created null is returned.
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
    } on Exception catch (e) {
      MqttLogger.log(
          'Subscriptionsmanager::createNewSubscription exception raised, text is $e');
      if (onSubscribeFail != null) {
        onSubscribeFail(topic);
      }
      return null;
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
    pendingUnsubscriptions[unsubscribeMsg.variableHeader.messageIdentifier] =
        topic;
  }

  /// Confirms a subscription has been made with the broker. Marks the sub as confirmed in the subs storage.
  /// Returns true on successful subscription, false on fail
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
    } else {
      return false;
    }

    // Check the Qos, we can get a failure indication(value 0x80) here if the
    // topic cannot be subscribed to.
    if (subAck.payload.qosGrants[0] == MqttQos.failure) {
      subscriptions.remove(topic);
      if (onSubscribeFail != null) {
        onSubscribeFail(topic);
        return false;
      }
    }
    // Success, call the subscribed callback
    if (onSubscribed != null) {
      onSubscribed(topic);
    }
    return true;
  }

  /// Cleans up after an unsubscribe message is received from the broker.
  /// returns true, always
  bool confirmUnsubscribe(MqttMessage msg) {
    final MqttUnsubscribeAckMessage unSubAck = msg;
    final String topic =
        pendingUnsubscriptions[unSubAck.variableHeader.messageIdentifier];
    subscriptions.remove(topic);
    pendingUnsubscriptions.remove(unSubAck.variableHeader.messageIdentifier);
    if (onUnsubscribed != null) {
      onUnsubscribed(topic);
    }
    return true;
  }

  /// Gets the current status of a subscription.
  MqttSubscriptionStatus getSubscriptionsStatus(String topic) {
    MqttSubscriptionStatus status = MqttSubscriptionStatus.doesNotExist;
    if (subscriptions.containsKey(topic)) {
      status = MqttSubscriptionStatus.active;
    }
    pendingSubscriptions.forEach((int key, Subscription value) {
      if (value.topic.rawTopic == topic) {
        status = MqttSubscriptionStatus.pending;
      }
    });
    return status;
  }
}
