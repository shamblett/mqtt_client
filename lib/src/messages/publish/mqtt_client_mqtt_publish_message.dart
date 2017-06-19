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

  /// Initializes a new instance of the MqttPublishMessage class.
  MqttPublishMessage() {
    this.header = new MqttHeader().asType(MqttMessageType.publish);
    this.variableHeader = new MqttPublishVariableHeader(this.header);
    this.payload = new MqttPublishPayload();
  }

  /// Initializes a new instance of the MqttPublishMessage class.
  MqttPublishMessage.fromByteBuffer(MqttHeader header,
      MqttByteBuffer messageStream) {
    this.header = header;
    readFrom(messageStream);
  }

  /// Reads a message from the supplied stream.
  void readFrom(MqttByteBuffer messageStream) {
    super.readFrom(messageStream);
    this.variableHeader = new MqttPublishVariableHeader.fromByteBuffer(
        this.header, messageStream);
    this.payload = new MqttPublishPayload.fromByteBuffer(
        this.header, this.variableHeader, messageStream);
  }

  /// Writes the message to the supplied stream.
  void writeTo(MqttByteBuffer messageStream) {
    this.header.writeTo(
        variableHeader.getWriteLength() + payload.getWriteLength(),
        messageStream);
    this.variableHeader.writeTo(messageStream);
    this.payload.writeTo(messageStream);
  }

  /// Sets the topic to publish data to.
  MqttPublishMessage toTopic(String topicName) {
    this.variableHeader.topicName = topicName;
    return this;
  }

  /// Appends data to publish to the end of the current message payload.
  MqttPublishMessage publishData(typed.Uint8Buffer data) {
    this.payload.message.addAll(data);
    return this;
  }

  /// Sets the message identifier of the message.
  MqttPublishMessage withMessageIdentifier(int messageIdentifier) {
    this.variableHeader.messageIdentifier = messageIdentifier;
    return this;
  }

  ///  Sets the Qos of the published message.
  MqttPublishMessage withQos(MqttQos qos) {
    this.header.withQos(qos);
    return this;
  }

  /// Removes the current published data.
  MqttPublishMessage clearPublishData() {
    this.payload.message.clear();
    return this;
  }

  String toString() {
    final StringBuffer sb = new StringBuffer();
    sb.write(super.toString());
    sb.writeln(variableHeader.toString());
    sb.writeln(payload.toString());
    return sb.toString();
  }
}
