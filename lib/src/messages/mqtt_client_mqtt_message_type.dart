/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// An enumeration of all available MQTT Message Types
enum MqttMessageType {
  /// Reserved by the MQTT spec, should not be used.
  reserved1,
  connect,
  connectAck,
  publish,
  publishAck,
  publishReceived,
  publishRelease,
  publishComplete,
  subscribe,
  subscribeAck,
  unsubscribe,
  unsubscribeAck,
  pingRequest,
  pingResponse,
  disconnect,

  /// Reserved by the MQTT spec, should not be used.
  reserved2
}
