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
typedef UnsubscribeCallback = void Function(String? topic);

/// A class that can manage the topic subscription process.
class SubscriptionsManager {
  ///  Creates a new instance of a SubscriptionsManager that uses the
  ///  specified connection to manage subscriptions.
  SubscriptionsManager(
      this.connectionHandler, this.publishingManager, this._clientEventBus) {
    connectionHandler!
        .registerForMessage(MqttMessageType.subscribeAck, confirmSubscription);
    connectionHandler!
        .registerForMessage(MqttMessageType.unsubscribeAck, confirmUnsubscribe);
    // Start listening for published messages and re subscribe events.
    _clientEventBus!.on<MessageReceived>().listen(publishMessageReceived);
    _clientEventBus!.on<Resubscribe>().listen(_resubscribe);
  }

  /// Dispenser used for keeping track of subscription ids
  MessageIdentifierDispenser messageIdentifierDispenser =
      MessageIdentifierDispenser();

  /// List of confirmed subscriptions, keyed on the topic name.
  Map<String, Subscription?> subscriptions = <String, Subscription?>{};

  /// A list of subscriptions that are pending acknowledgement, keyed
  /// on the message identifier.
  Map<int?, Subscription> pendingSubscriptions = <int?, Subscription>{};

  /// A list of unsubscribe requests waiting for an unsubscribe ack message.
  /// Index is the message identifier of the unsubscribe message
  Map<int?, String> pendingUnsubscriptions = <int?, String>{};

  /// The connection handler that we use to subscribe to subscription
  /// acknowledgements.
  IMqttConnectionHandler? connectionHandler;

  /// Publishing manager used for passing on published messages to subscribers.
  PublishingManager? publishingManager;

  /// Subscribe and Unsubscribe callbacks
  SubscribeCallback? onSubscribed;

  /// Unsubscribed
  UnsubscribeCallback? onUnsubscribed;

  /// Subscription failed callback
  SubscribeFailCallback? onSubscribeFail;

  /// Re subscribe on auto reconnect.
  bool resubscribeOnAutoReconnect = true;

  /// The event bus
  final events.EventBus? _clientEventBus;

  /// Stream for all subscribed topics
  final _subscriptionNotifier =
      StreamController<List<MqttReceivedMessage<MqttMessage>>>.broadcast(
          sync: true);

  /// Subscription notifier
  Stream<List<MqttReceivedMessage<MqttMessage>>> get subscriptionNotifier =>
      _subscriptionNotifier.stream;

  /// Registers a new subscription with the subscription manager.
  Subscription? registerSubscription(String topic, MqttQos qos) {
    var cn = tryGetExistingSubscription(topic);
    return cn ??= createNewSubscription(topic, qos);
  }

  /// Gets a view on the existing observable, if the subscription
  /// already exists.
  Subscription? tryGetExistingSubscription(String topic) {
    final retSub = subscriptions[topic];
    if (retSub == null) {
      // Search the pending subscriptions
      for (final sub in pendingSubscriptions.values) {
        if (sub.topic.rawTopic == topic) {
          return sub;
        }
      }
    }
    return retSub;
  }

  /// Creates a new subscription for the specified topic.
  /// If the subscription cannot be created null is returned.
  Subscription? createNewSubscription(String topic, MqttQos? qos) {
    try {
      final subscriptionTopic = SubscriptionTopic(topic);
      // Get an ID that represents the subscription. We will use this
      // same ID for unsubscribe as well.
      final msgId = messageIdentifierDispenser.getNextMessageIdentifier();
      final sub = Subscription();
      sub.topic = subscriptionTopic;
      sub.qos = qos;
      sub.messageIdentifier = msgId;
      sub.createdTime = DateTime.now();
      pendingSubscriptions[sub.messageIdentifier] = sub;
      // Build a subscribe message for the caller and send it off to the broker.
      final msg = MqttSubscribeMessage()
          .withMessageIdentifier(sub.messageIdentifier)
          .toTopic(sub.topic.rawTopic)
          .atQos(sub.qos);
      connectionHandler!.sendMessage(msg);
      return sub;
    } on Exception catch (e) {
      MqttLogger.log('Subscriptionsmanager::createNewSubscription '
          'exception raised, text is $e');
      if (onSubscribeFail != null) {
        onSubscribeFail!(topic);
      }
      return null;
    }
  }

  /// Publish message received
  void publishMessageReceived(MessageReceived event) {
    final topic = event.topic;
    final msg = MqttReceivedMessage<MqttMessage>(topic.rawTopic, event.message);
    _subscriptionNotifier.add([msg]);
  }

  /// Unsubscribe from a topic.
  /// Some brokers(AWS for instance) need to have each un subscription acknowledged, use
  /// the [expectAcknowledge] parameter for this, default is false.
  void unsubscribe(String topic, {expectAcknowledge = false}) {
    final unsubscribeMsg = MqttUnsubscribeMessage()
        .withMessageIdentifier(
            messageIdentifierDispenser.getNextMessageIdentifier())
        .fromTopic(topic);
    if (expectAcknowledge) {
      unsubscribeMsg.expectAcknowledgement();
    }
    connectionHandler!.sendMessage(unsubscribeMsg);
    pendingUnsubscriptions[unsubscribeMsg.variableHeader!.messageIdentifier] =
        topic;
  }

  /// Re subscribe.
  /// Unsubscribes all confirmed subscriptions and re subscribes them
  /// without sending unsubscribe messages to the broker.
  void resubscribe() {
    for (final subscription in subscriptions.values) {
      createNewSubscription(subscription!.topic.rawTopic, subscription.qos);
    }
    subscriptions.clear();
  }

  /// Confirms a subscription has been made with the broker.
  /// Marks the sub as confirmed in the subs storage.
  /// Returns true on successful subscription, false on fail.
  bool confirmSubscription(MqttMessage? msg) {
    final subAck = msg as MqttSubscribeAckMessage;
    String topic;
    if (pendingSubscriptions
        .containsKey(subAck.variableHeader!.messageIdentifier)) {
      topic = pendingSubscriptions[subAck.variableHeader!.messageIdentifier]!
          .topic
          .rawTopic;
      subscriptions[topic] =
          pendingSubscriptions[subAck.variableHeader!.messageIdentifier];
      pendingSubscriptions.remove(subAck.variableHeader!.messageIdentifier);
    } else {
      return false;
    }

    // Check the Qos, we can get a failure indication(value 0x80) here if the
    // topic cannot be subscribed to.
    if (subAck.payload.qosGrants.isEmpty ||
        subAck.payload.qosGrants[0] == MqttQos.failure) {
      subscriptions.remove(topic);
      if (onSubscribeFail != null) {
        onSubscribeFail!(topic);
        return false;
      }
    }
    // Success, call the subscribed callback
    if (onSubscribed != null) {
      onSubscribed!(topic);
    }
    return true;
  }

  /// Cleans up after an unsubscribe message is received from the broker.
  /// returns true, always
  bool confirmUnsubscribe(MqttMessage? msg) {
    final unSubAck = msg as MqttUnsubscribeAckMessage;
    final topic =
        pendingUnsubscriptions[unSubAck.variableHeader.messageIdentifier];
    subscriptions.remove(topic);
    pendingUnsubscriptions.remove(unSubAck.variableHeader.messageIdentifier);
    if (onUnsubscribed != null) {
      onUnsubscribed!(topic);
    }
    return true;
  }

  /// Gets the current status of a subscription.
  MqttSubscriptionStatus getSubscriptionsStatus(String topic) {
    var status = MqttSubscriptionStatus.doesNotExist;
    if (subscriptions.containsKey(topic)) {
      status = MqttSubscriptionStatus.active;
    }
    pendingSubscriptions.forEach((int? key, Subscription value) {
      if (value.topic.rawTopic == topic) {
        status = MqttSubscriptionStatus.pending;
      }
    });
    return status;
  }

  // Re subscribe.
  // Takes all active completed subscriptions and re subscribes them if
  // [resubscribeOnAutoReconnect] is true.
  // Automatically fired after auto reconnect has completed.
  void _resubscribe(Resubscribe resubscribeEvent) {
    if (resubscribeOnAutoReconnect) {
      MqttLogger.log(
          'Subscriptionsmanager::_resubscribe - resubscribing from auto reconnect ${resubscribeEvent.fromAutoReconnect}');
      for (final subscription in subscriptions.values) {
        createNewSubscription(subscription!.topic.rawTopic, subscription.qos);
      }
      subscriptions.clear();
    } else {
      MqttLogger.log('Subscriptionsmanager::_resubscribe - '
          'NOT resubscribing from auto reconnect ${resubscribeEvent.fromAutoReconnect}, resubscribeOnAutoReconnect is false');
    }
  }
}
