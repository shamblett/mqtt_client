/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Enumeration that indicates the origin of a client disconnection
enum MqttDisconnectionOrigin {
  /// Unsolicited, i.e. not requested by the client,
  /// for example a broker/network initiated disconnect
  unsolicited,

  /// Solicited, i.e. requested by the client,
  /// for example disconnect called on the client.
  solicited,

  /// None set
  none
}

/// Enumeration that indicates various client connection states
enum MqttConnectionState {
  /// The MQTT Connection is in the process of disconnecting from the broker.
  disconnecting,

  /// MQTT Connection is not currently connected to any broker.
  disconnected,

  /// The MQTT Connection is in the process of connecting to the broker.
  connecting,

  /// The MQTT Connection is currently connected to the broker.
  connected,

  /// The MQTT Connection is faulted and no longer communicating
  /// with the broker.
  faulted
}
