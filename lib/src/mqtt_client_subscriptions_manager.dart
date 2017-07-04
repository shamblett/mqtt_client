/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 30/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// A class that can manage the topic subscription process.
class SubscriptionsManager extends Object with events.EventDetector {
  /// Used to synchronize access to subscriptions.
  bool _subscriptionPadlock = false;

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
  IPublishingManager publishingManager;

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
