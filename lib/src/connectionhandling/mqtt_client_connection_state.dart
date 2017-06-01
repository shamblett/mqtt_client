/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Enumeration that indicates various client connection states
enum ConnectionState {
  /// The MQTT Connection is in the process of disconnecting from the broker.
  disconnecting,

  /// MQTT Connection is not currently connected to any broker.
  disconnected,

  /// The MQTT Connection is in the process of connecting to the broker.
  connecting,

  /// The MQTT Connection is currently connected to the broker.
  connected,

  /// The MQTT Connection is faulted and no longer communicating with the broker.
  faulted
}