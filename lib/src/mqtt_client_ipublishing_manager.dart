/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 30/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Interface that defines how the publishing manager publishes
/// messages to the broker and how it passed on messages that are
/// received from the broker.
abstract class IPublishingManager {
  /// Publish a message to the broker on the specified topic.
  /// The topic to send the message to
  /// The QOS to use when publishing the message.
  /// The message to send.
  /// The message identifier assigned to the message.
  int publish(
      PublicationTopic topic, MqttQos qualityOfService, typed.Uint8Buffer data);

  /// The message received event
  MessageReceived? publishEvent;
}
