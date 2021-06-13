/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Implementation of an MQTT Publish Message, used for publishing
/// telemetry data along a live MQTT stream.
class MqttPublishMessage extends MqttMessage {
  /// Initializes a new instance of the MqttPublishMessage class.
  MqttPublishMessage() {
    header = MqttHeader().asType(MqttMessageType.publish);
    variableHeader = MqttPublishVariableHeader(header);
    payload = MqttPublishPayload();
  }

  /// Initializes a new instance of the MqttPublishMessage class.
  MqttPublishMessage.fromByteBuffer(
      MqttHeader header, MqttByteBuffer messageStream) {
    this.header = header;
    readFrom(messageStream);
  }

  /// The variable header contents. Contains extended metadata about the message
  MqttPublishVariableHeader? variableHeader;

  /// Gets or sets the payload of the Mqtt Message.
  late MqttPublishPayload payload;

  /// Reads a message from the supplied stream.
  @override
  void readFrom(MqttByteBuffer messageStream) {
    super.readFrom(messageStream);
    variableHeader =
        MqttPublishVariableHeader.fromByteBuffer(header, messageStream);
    payload = MqttPublishPayload.fromByteBuffer(
        header, variableHeader, messageStream);
  }

  /// Writes the message to the supplied stream.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    final variableHeaderLength = variableHeader!.getWriteLength();
    final payloadLength = payload.getWriteLength();
    header!.writeTo(variableHeaderLength + payloadLength, messageStream);
    variableHeader!.writeTo(messageStream);
    payload.writeTo(messageStream);
  }

  /// Sets the topic to publish data to.
  MqttPublishMessage toTopic(String topicName) {
    variableHeader!.topicName = topicName;
    return this;
  }

  /// Appends data to publish to the end of the current message payload.
  MqttPublishMessage publishData(typed.Uint8Buffer data) {
    payload.message.addAll(data);
    return this;
  }

  /// Sets the message identifier of the message.
  MqttPublishMessage withMessageIdentifier(int messageIdentifier) {
    variableHeader!.messageIdentifier = messageIdentifier;
    return this;
  }

  ///  Sets the Qos of the published message.
  MqttPublishMessage withQos(MqttQos qos) {
    header!.withQos(qos);
    return this;
  }

  /// Removes the current published data.
  MqttPublishMessage clearPublishData() {
    payload.message.clear();
    return this;
  }

  /// Set the retain flag on the message
  void setRetain({bool? state}) {
    if ((state != null) && state) {
      header!.shouldBeRetained();
    }
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(super.toString());
    sb.writeln(variableHeader.toString());
    sb.writeln(payload.toString());
    return sb.toString();
  }
}
