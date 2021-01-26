/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Implementation of an MQTT Unsubscribe Message.
class MqttUnsubscribeMessage extends MqttMessage {
  /// Initializes a new instance of the MqttUnsubscribeMessage class.
  MqttUnsubscribeMessage() {
    header = MqttHeader().asType(MqttMessageType.unsubscribe);
    variableHeader = MqttUnsubscribeVariableHeader();
    payload = MqttUnsubscribePayload();
  }

  /// Initializes a new instance of the MqttUnsubscribeMessage class.
  MqttUnsubscribeMessage.fromByteBuffer(
      MqttHeader header, MqttByteBuffer messageStream) {
    this.header = header;
    readFrom(messageStream);
  }

  /// Gets or sets the variable header contents. Contains extended
  /// metadata about the message.
  MqttUnsubscribeVariableHeader? variableHeader;

  /// Gets or sets the payload of the Mqtt Message.
  late MqttUnsubscribePayload payload;

  /// Writes the message to the supplied stream.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    // If the protocol is V3.1.1 the following header fields
    // must be set as below as in this protocol they are reserved.
    if (Protocol.version == MqttClientConstants.mqttV311ProtocolVersion) {
      header!.duplicate = false;
      header!.qos = MqttQos.atLeastOnce;
      header!.retain = false;
    }
    header!.writeTo(variableHeader!.getWriteLength() + payload.getWriteLength(),
        messageStream);
    variableHeader!.writeTo(messageStream);
    payload.writeTo(messageStream);
  }

  /// Reads a message from the supplied stream.
  @override
  void readFrom(MqttByteBuffer messageStream) {
    variableHeader =
        MqttUnsubscribeVariableHeader.fromByteBuffer(messageStream);
    payload = MqttUnsubscribePayload.fromByteBuffer(
        header, variableHeader, messageStream);
  }

  /// Adds a topic to the list of topics to unsubscribe from.
  MqttUnsubscribeMessage fromTopic(String topic) {
    payload.addSubscription(topic);
    return this;
  }

  /// Sets the message identifier on the subscribe message.
  MqttUnsubscribeMessage withMessageIdentifier(int messageIdentifier) {
    variableHeader!.messageIdentifier = messageIdentifier;
    return this;
  }

  /// Sets the message up to request acknowledgement from the
  /// broker for each topic subscription.
  MqttUnsubscribeMessage expectAcknowledgement() {
    header!.withQos(MqttQos.atLeastOnce);
    return this;
  }

  /// Sets the duplicate flag for the message to indicate its a
  /// duplicate of a previous message type with the same message identifier.
  MqttUnsubscribeMessage isDuplicate() {
    header!.isDuplicate();
    return this;
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
