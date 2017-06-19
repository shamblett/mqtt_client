/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Implementation of an MQTT Publish Message, used for publishing telemetry data along a live MQTT stream.
class MqttPublishMessage extends MqttMessage {
  /// The variable header contents. Contains extended metadata about the message
  MqttPublishVariableHeader variableHeader;

  /// Gets or sets the payload of the Mqtt Message.
  MqttPublishPayload payload;

  /// Initializes a new instance of the <see cref="MqttPublishMessage" /> class.
  MqttPublishMessage() {
    this.header = new MqttHeader().asType(MqttMessageType.publish);
    this.variableHeader = new MqttPublishVariableHeader(this.header);
    this.payload = new MqttPublishPayload();
  }
}
