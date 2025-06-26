/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 30/06/2017
 * Copyright :  S.Hamblett
 */

part of '../mqtt_client.dart';

/// Subscribed and Unsubscribed callback typedefs
typedef SubscribeCallback = void Function(String topic);
typedef SubscribeFailCallback = void Function(String topic);
typedef UnsubscribeCallback = void Function(String? topic);

/// A class that can manage the topic subscription process.
class SubscriptionsManager {
  /// Dispenser used for keeping track of subscription ids
  MessageIdentifierDispenser messageIdentifierDispenser =
      MessageIdentifierDispenser();

  /// List of confirmed subscriptions, keyed on the message identifier..
  Map<int, Subscription> subscriptions = <int, Subscription>{};

  /// A list of subscriptions that are pending acknowledgement, keyed
  /// on the message identifier.
  Map<int, Subscription> pendingSubscriptions = <int, Subscription>{};

  /// A list of unsubscribe requests waiting for an unsubscribe ack message.
  /// Index is the message identifier of the unsubscribe message
  Map<int, String> pendingUnsubscriptions = <int, String>{};

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
        sync: true,
      );

  /// Subscription notifier
  Stream<List<MqttReceivedMessage<MqttMessage>>> get subscriptionNotifier =>
      _subscriptionNotifier.stream;

  ///  Creates a new instance of a SubscriptionsManager that uses the
  ///  specified connection to manage subscriptions.
  SubscriptionsManager(
    this.connectionHandler,
    this.publishingManager,
    this._clientEventBus,
  ) {
    connectionHandler!.registerForMessage(
      MqttMessageType.subscribeAck,
      confirmSubscription,
    );
    connectionHandler!.registerForMessage(
      MqttMessageType.unsubscribeAck,
      confirmUnsubscribe,
    );
    // Start listening for published messages and re subscribe events.
    _clientEventBus!.on<MessageReceived>().listen(publishMessageReceived);
    _clientEventBus!.on<Resubscribe>().listen(_resubscribe);
  }

  /// Registers a new subscription with the subscription manager.
  Subscription? registerSubscription(String topic, MqttQos qos) {
    var cn = tryGetExistingSubscription(topic);
    return cn ??= createNewSubscription(topic, qos);
  }

  /// Registers a new batch subscription with the subscription manager.
  Subscription? registerBatchSubscription(
    List<BatchSubscription> subscriptions,
  ) {
    // Use the first topic in the batch
    var cn = tryGetExistingSubscription(subscriptions.first.topic);
    return cn ??= createNewBatchSubscription(subscriptions);
  }

  /// Gets a view on the existing observable, if the subscription
  /// already exists.
  Subscription? tryGetExistingSubscription(String topic) {
    for (final sub in subscriptions.values) {
      if (sub.topic.rawTopic == topic) {
        return sub;
      }
    }
    // Search the pending subscriptions
    for (final sub in pendingSubscriptions.values) {
      if (sub.topic.rawTopic == topic) {
        return sub;
      }
    }
    return null;
  }

  /// Creates a new subscription for the specified topic.
  /// If the subscription cannot be created null is returned.
  Subscription? createNewSubscription(String topic, MqttQos? qos) {
    try {
      final subscriptionTopic = SubscriptionTopic(topic);
      // Get an ID that represents the subscription. We will use this
      // same ID for unsubscribe as well.
      final messageIdentifier = messageIdentifierDispenser
          .getNextMessageIdentifier();
      final sub = Subscription();
      sub.topic = subscriptionTopic;
      sub.qos = qos;
      sub.messageIdentifier = messageIdentifier;
      sub.createdTime = DateTime.now();
      pendingSubscriptions[messageIdentifier] = sub;
      // Build a subscribe message for the caller and send it off to the broker.
      final msg = MqttSubscribeMessage()
          .withMessageIdentifier(sub.messageIdentifier)
          .toTopic(sub.topic.rawTopic)
          .atQos(sub.qos);
      connectionHandler!.sendMessage(msg);
      return sub;
    } on Exception catch (e) {
      MqttLogger.log(
        'Subscriptionsmanager::createNewSubscription '
        'exception raised, text is $e',
      );
      if (onSubscribeFail != null) {
        onSubscribeFail!(topic);
      }
      return null;
    }
  }

  /// Creates a new batch subscription for the specified topic.
  /// If the subscription cannot be created null is returned.
  Subscription? createNewBatchSubscription(
    List<BatchSubscription> subscriptions,
  ) {
    try {
      final subscriptionTopic = SubscriptionTopic(subscriptions.first.topic);
      // Get an ID that represents the subscription. We will use this
      // same ID for unsubscribe as well.
      final messageIdentifier = messageIdentifierDispenser
          .getNextMessageIdentifier();
      final sub = Subscription();
      sub.batch = true;
      sub.topic = subscriptionTopic;
      sub.batchSubscriptions = subscriptions;
      sub.messageIdentifier = messageIdentifier;
      sub.createdTime = DateTime.now();
      pendingSubscriptions[messageIdentifier] = sub;
      // Build a subscribe message for the caller and send it off to the broker.
      final msg = MqttSubscribeMessage().withMessageIdentifier(
        messageIdentifier,
      );
      for (final subscription in subscriptions) {
        msg.toTopic(subscription.topic);
        msg.atQos(subscription.qos);
      }
      connectionHandler!.sendMessage(msg);
      return sub;
    } on Exception catch (e) {
      MqttLogger.log(
        'Subscriptionsmanager::createNewBatchSubscription '
        'exception raised, text is $e',
      );
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
    final messageIdentifier = messageIdentifierDispenser
        .getNextMessageIdentifier();
    final unsubscribeMsg = MqttUnsubscribeMessage()
        .withMessageIdentifier(
          messageIdentifierDispenser.getNextMessageIdentifier(),
        )
        .fromTopic(topic);
    if (expectAcknowledge) {
      unsubscribeMsg.expectAcknowledgement();
    }
    connectionHandler!.sendMessage(unsubscribeMsg);
    pendingUnsubscriptions[messageIdentifier] = topic;
  }

  /// Re subscribe.
  /// Unsubscribes all confirmed subscriptions and re subscribes them
  /// without sending unsubscribe messages to the broker.
  void resubscribe() {
    for (final subscription in subscriptions.values) {
      createNewSubscription(subscription.topic.rawTopic, subscription.qos);
    }
    subscriptions.clear();
  }

  /// Confirms a subscription has been made with the broker.
  /// Moves the subscription from pending to active if the subscription has
  /// not failed.
  /// Batch subscriptions only fail if all the subscriptions in the batch fail.
  /// Returns true on successful subscription, false on fail.
  bool confirmSubscription(MqttMessage? msg) {
    final subAck = msg as MqttSubscribeAckMessage;
    int messageIdentifier = subAck.variableHeader!.messageIdentifier!;
    Subscription sub = Subscription();

    // If not pending return false.
    if (pendingSubscriptions.containsKey(messageIdentifier)) {
      sub = pendingSubscriptions[messageIdentifier]!;
    } else {
      return false;
    }

    // Check the Qos, we can get a failure indication(value 0x80) here if the
    // topic cannot be subscribed to. For batch subscriptions all the
    // subscriptions must fail for the subscription to be treated as a failure.
    if (!sub.batch) {
      if (subAck.payload.qosGrants.isEmpty ||
          subAck.payload.qosGrants.first == MqttQos.failure) {
        pendingSubscriptions.remove(messageIdentifier);
        if (onSubscribeFail != null) {
          onSubscribeFail!(sub.topic.rawTopic);
        }
        return false;
      }
    } else {
      if (subAck.payload.qosGrants.isEmpty ||
          sub.totalFailedSubscriptions == sub.totalBatchSubscriptions) {
        pendingSubscriptions.remove(messageIdentifier);
        if (onSubscribeFail != null) {
          onSubscribeFail!(sub.topic.rawTopic);
        }
        return false;
      }
    }

    // Subscription is valid, move to subscriptions, i.e. active
    pendingSubscriptions.remove(messageIdentifier);

    // Update individual subscription status from batch subscription.
    if (sub.batch) {
      final res = sub.updateBatchQos(subAck.payload.qosGrants);
      if (!res) {
        return false;
      }
    }

    // Success, call the subscribed callback
    if (onSubscribed != null) {
      onSubscribed!(sub.topic.rawTopic);
    }
    return true;
  }

  /// Cleans up after an unsubscribe message is received from the broker.
  /// returns true, always
  bool confirmUnsubscribe(MqttMessage? msg) {
    final unSubAck = msg as MqttUnsubscribeAckMessage;
    final messageIdentifier = unSubAck.variableHeader.messageIdentifier;
    subscriptions.remove(messageIdentifier);
    pendingUnsubscriptions.remove(messageIdentifier);
    if (onUnsubscribed != null) {
      onUnsubscribed!(unSubAck.variableHeader.topicName);
    }
    return true;
  }

  /// Gets the current status of a subscription.
  MqttSubscriptionStatus getSubscriptionsStatus(String topic) {
    var status = MqttSubscriptionStatus.doesNotExist;

    Subscription sub = subscriptions.values.firstWhere(
      (s) => s.topic.rawTopic == topic,
      orElse: (() => Subscription()..qos = MqttQos.reserved1),
    );
    if (sub.qos != MqttQos.reserved1) {
      status = MqttSubscriptionStatus.active;
    }

    sub = pendingSubscriptions.values.firstWhere(
      (s) => s.topic.rawTopic == topic,
      orElse: (() => Subscription()..qos = MqttQos.reserved1),
    );
    if (sub.qos != MqttQos.reserved1) {
      status = MqttSubscriptionStatus.pending;
    }

    return status;
  }

  /// Gets the current status of a subscription.
  MqttSubscriptionStatus getSubscriptionsStatusBySubscription(
    Subscription sub,
  ) {
    var status = MqttSubscriptionStatus.doesNotExist;
    if (subscriptions.containsValue(sub)) {
      status == MqttSubscriptionStatus.active;
    }
    if (pendingSubscriptions.containsValue(sub)) {
      status == MqttSubscriptionStatus.pending;
    }
    return status;
  }

  /// Closes the subscription notifier
  void closeSubscriptionNotifier() => _subscriptionNotifier.close();

  // Re subscribe.
  // Takes all active completed and pending subscriptions and re subscribes them if
  // [resubscribeOnAutoReconnect] is true.
  // Automatically fired after auto reconnect has completed.
  void _resubscribe(Resubscribe resubscribeEvent) {
    if (resubscribeOnAutoReconnect) {
      MqttLogger.log(
        'Subscriptionsmanager::_resubscribe - resubscribing from auto reconnect ${resubscribeEvent.fromAutoReconnect}',
      );
      final subscriptionList = subscriptions.values.toList();
      final pendingSubscriptionList = pendingSubscriptions.values.toList();
      subscriptions.clear();
      pendingSubscriptions.clear();

      for (final subscription in [
        ...subscriptionList,
        ...pendingSubscriptionList,
      ]) {
        createNewSubscription(subscription.topic.rawTopic, subscription.qos);
      }
    } else {
      MqttLogger.log(
        'Subscriptionsmanager::_resubscribe - '
        'NOT resubscribing from auto reconnect ${resubscribeEvent.fromAutoReconnect}, resubscribeOnAutoReconnect is false',
      );
    }
  }
}
