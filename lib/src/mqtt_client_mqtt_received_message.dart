/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Represents a MQTT message that has been received from a broker.
class MqttReceivedMessage<T> extends ChangeRecord {
  /// The topic the message was received on.
  String topic;

  /// The payload of the message received.
  T payload;

  /// Initializes a new instance of an MqttReceivedMessage class.
  MqttReceivedMessage(String topic, T payload) {
    this.topic = topic;
    this.payload = payload;
  }
}
