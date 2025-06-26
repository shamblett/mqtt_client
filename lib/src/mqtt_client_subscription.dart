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

  /// Empty if a single subscription.
  List<BatchSubscription> batchSubscriptions = [];

  MqttQos _qos = MqttQos.failure;

  SubscriptionTopic _topic = SubscriptionTopic('rawtopic');

  /// QoS, if batch this is the QoS of the first topic.
  MqttQos get qos {
    if (batch && batchSubscriptions.isNotEmpty) {
      return batchSubscriptions.first.qos;
    }
    return _qos;
  }

  /// The Topic that is subscribed to.
  /// For a batch subscription the first topic in the batch.
  SubscriptionTopic get topic => batch && batchSubscriptions.isNotEmpty
      ? SubscriptionTopic(batchSubscriptions.first.topic)
      : _topic;

  /// Failed batch subscriptions. Only valid when the subscription becomes
  /// active, i.e. we know the status of the QoS grants from the broker.
  List<BatchSubscription> get failedSubscriptions =>
      batchSubscriptions.where((s) => s.qos == MqttQos.failure).toList();

  /// Succeeded batch subscriptions. Will reflect the user supplied QoS
  /// levels while the subscription is pending.
  List<BatchSubscription> get succeededSubscriptions =>
      batchSubscriptions.where((s) => s.qos != MqttQos.failure).toList();

  /// Total failed batch subscriptions.
  int get totalFailedSubscriptions => failedSubscriptions.length;

  /// Total succeeded batch subscriptions.
  int get totalSucceededSubscriptions => succeededSubscriptions.length;

  /// Total batch subscriptions.
  int get totalBatchSubscriptions =>
      totalFailedSubscriptions + totalSucceededSubscriptions;

  @override
  int get hashCode => topic.hashCode + qos.hashCode + batch.hashCode;

  set topic(SubscriptionTopic topic) => _topic = topic;

  set qos(MqttQos qos) {
    if (!batch) {
      _qos = qos;
    }
  }

  /// Update the subscriptions in the subscriptions list with the QoS
  /// grants returned by the broker.
  /// Returns false if the number of qos grants is not equal to the
  /// number of subscriptions.
  bool updateBatchQos(List<MqttQos> qosList) {
    if (qosList.length != totalBatchSubscriptions) {
      return false;
    }
    for (int i = 0; i < totalBatchSubscriptions; i++) {
      batchSubscriptions[i].qos = qosList[i];
    }
    qos = batchSubscriptions.first.qos;

    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subscription &&
          runtimeType == other.runtimeType &&
          topic.rawTopic == other.topic.rawTopic &&
          qos == other.qos &&
          batch == other.batch &&
          messageIdentifier == other.messageIdentifier;

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln(
      'Subscription:: Batch: $batch, MID: $messageIdentifier, Topic: ${topic.rawTopic}, QoS: $qos, Total Batch: $totalBatchSubscriptions',
    );
    return sb.toString();
  }
}

/// A subscription used in batch subscription processing.
class BatchSubscription {
  final String topic;

  /// Qos, default to failure.
  MqttQos qos = MqttQos.failure;

  @override
  int get hashCode => topic.hashCode + qos.hashCode;

  BatchSubscription(this.topic, this.qos);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchSubscription &&
          runtimeType == other.runtimeType &&
          topic == other.topic &&
          qos == other.qos;

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln('BatchSubscription:: Topic: $topic, QoS: $qos');
    return sb.toString();
  }
}
