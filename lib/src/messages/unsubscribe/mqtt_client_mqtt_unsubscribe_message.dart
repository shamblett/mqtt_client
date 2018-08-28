/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Implementation of an MQTT Unsubscribe Message.
class MqttUnsubscribeMessage extends MqttMessage {
  /// Gets or sets the variable header contents. Contains extended metadata about the message
  MqttUnsubscribeVariableHeader variableHeader;

  /// Gets or sets the payload of the Mqtt Message.
  MqttUnsubscribePayload payload;

  /// Initializes a new instance of the MqttUnsubscribeMessage class.
  MqttUnsubscribeMessage() {
    this.header = MqttHeader().asType(MqttMessageType.unsubscribe);
    this.variableHeader = MqttUnsubscribeVariableHeader();
    this.payload = MqttUnsubscribePayload();
  }

  /// Initializes a new instance of the MqttUnsubscribeMessage class.
  MqttUnsubscribeMessage.fromByteBuffer(
      MqttHeader header, MqttByteBuffer messageStream) {
    this.header = header;
    readFrom(messageStream);
  }

  /// Writes the message to the supplied stream.
  void writeTo(MqttByteBuffer messageStream) {
    this.header.writeTo(
        this.variableHeader.getWriteLength() + this.payload.getWriteLength(),
        messageStream);
    this.variableHeader.writeTo(messageStream);
    this.payload.writeTo(messageStream);
  }

  /// Reads a message from the supplied stream.
  void readFrom(MqttByteBuffer messageStream) {
    this.variableHeader =
        MqttUnsubscribeVariableHeader.fromByteBuffer(messageStream);
    this.payload = MqttUnsubscribePayload.fromByteBuffer(
        header, variableHeader, messageStream);
  }

  /// Adds a topic to the list of topics to unsubscribe from.
  MqttUnsubscribeMessage fromTopic(String topic) {
    this.payload.addSubscription(topic);
    return this;
  }

  /// Sets the message identifier on the subscribe message.
  MqttUnsubscribeMessage withMessageIdentifier(int messageIdentifier) {
    this.variableHeader.messageIdentifier = messageIdentifier;
    return this;
  }

  /// Sets the message up to request acknowledgement from the broker for each topic subscription.
  MqttUnsubscribeMessage expectAcknowledgement() {
    this.header.withQos(MqttQos.atLeastOnce);
    return this;
  }

  /// Sets the duplicate flag for the message to indicate its a duplicate of a previous message type
  /// with the same message identifier.
  MqttUnsubscribeMessage isDuplicate() {
    this.header.isDuplicate();
    return this;
  }

  String toString() {
    final StringBuffer sb = StringBuffer();
    sb.write(super.toString());
    sb.writeln(variableHeader.toString());
    sb.writeln(payload.toString());
    return sb.toString();
  }
}
