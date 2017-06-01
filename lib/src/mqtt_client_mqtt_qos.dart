/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Enumeration of available QoS types.
enum MqttQos {
  /// QOS Level 0 - Message is not guaranteed delivery. No retries are made to ensure delivery is successful.
  atMostOnce,

  /// QOS Level 1 - Message is guaranteed delivery. It will be delivered at least one time, but may be delivered
  /// more than once if network errors occur.
  atLeastOnce,

  /// QOS Level 2 - Message will be delivered once, and only once. Message will be retried until
  /// it is successfully sent..
  exactlyOnce,

  /// Reserved by the MQTT Spec. Currently unused.
  reserved1
}
