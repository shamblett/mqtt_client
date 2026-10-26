// ignore_for_file: prefer-static-class

part of '../mqtt_client.dart';

// MQTT-2.3.1-2/3: pending outbound exchanges share one packet identifier space.
// Callers record the exchange before sending; null means no identifier is free.
int? _allocatePacketIdentifier(
  MessageIdentifierDispenser dispenser, {
  PublishingManager? publishing,
  SubscriptionsManager? subscriptions,
  bool forSubscription = false,
}) {
  for (
    var i = MessageIdentifierDispenser.startMessageIdentifier;
    i < MessageIdentifierDispenser.maxMessageIdentifier;
    i++
  ) {
    final id = dispenser.getNextMessageIdentifier();
    if (publishing?.publishedMessages.containsKey(id) ?? false) continue;
    if (subscriptions != null) {
      if (subscriptions.pendingSubscriptions.containsKey(id) ||
          subscriptions.pendingUnsubscriptions.containsKey(id) ||
          subscriptions._unsubscriptionsAwaitingAck.contains(id)) {
        continue;
      }
      // Confirmed subscriptions still use their IDs as map keys. Only new
      // subscriptions must avoid these keys; publishing may reuse them.
      if (forSubscription && subscriptions.subscriptions.containsKey(id)) {
        continue;
      }
    }
    return id;
  }
  return null;
}
