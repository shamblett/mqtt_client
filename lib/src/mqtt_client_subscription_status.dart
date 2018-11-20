/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Describes the status of a subscription
enum MqttSubscriptionStatus {
  /// The subscription does not exist / is not known
  doesNotExist,

  /// The subscription is currently pending acknowledgement by a broker.
  pending,

  /// The subscription is currently active and messages will be received.
  active
}
