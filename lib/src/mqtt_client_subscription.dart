/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of '../mqtt_client.dart';

/// a class that captures data related to an individual subscription or a
/// batch subscription.
///
/// Note that batch subscriptions are treated as an individual subscription
/// as only one subscription message is sent to the broker.
///
/// A batch subscription contains additional information see [batchSubscriptions]
/// below.
class Subscription extends observe.Observable<observe.ChangeRecord> {
  /// The message identifier assigned to the subscription
  int? messageIdentifier;

  /// Indicates a batch subscription.
  bool batch = false;

  /// The time the subscription was created.
  DateTime? createdTime;

  /// The QOS level of the topics subscription
  /// For a baych subscription the first topic in the batch.
  MqttQos? qos;

  /// Empty if a single subscription.
  List<BatchSubscription> batchSubscriptions = [];

  late SubscriptionTopic _topic;

  /// The Topic that is subscribed to.
  /// For a batch subscription the first topic in the batch.
  SubscriptionTopic get topic =>
      batch ? SubscriptionTopic(batchSubscriptions.first.topic) : _topic;

  /// Failed batch subscriptions.
  List<BatchSubscription> get failedSubscriptions =>
      batchSubscriptions.where((s) => s.qosLevel == MqttQos.failure).toList();

  /// Succeeded batch subscriptions.
  List<BatchSubscription> get succeededSubscriptions =>
      batchSubscriptions.where((s) => s.qosLevel != MqttQos.failure).toList();

  /// Total failed batch subscriptions.
  int get totalFailedSubscriptions => failedSubscriptions.length;

  /// Total succeeded batch subscriptions.
  int get totalSucceededSubscriptions => succeededSubscriptions.length;

  /// Total batch subscriptions.
  int get totalBatchSubscriptions =>
      totalFailedSubscriptions + totalSucceededSubscriptions;

  set topic(SubscriptionTopic topic) => _topic = topic;
}

/// A subscription used in batch subscription processing.
class BatchSubscription {
  final String topic;

  final MqttQos qosLevel;

  BatchSubscription(this.topic, this.qosLevel);
}
