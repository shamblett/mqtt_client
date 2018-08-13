/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Implementation of an MQTT Subscribe Ack Message.
class MqttSubscribeAckMessage extends MqttMessage {
  /// Gets or sets the variable header contents. Contains extended metadata about the message
  MqttSubscribeAckVariableHeader variableHeader;

  /// Gets or sets the payload of the Mqtt Message.
  MqttSubscribeAckPayload payload;

  /// Initializes a new instance of the MqttSubscribeAckMessage class.
  MqttSubscribeAckMessage() {
    this.header = MqttHeader().asType(MqttMessageType.subscribeAck);
    this.variableHeader = MqttSubscribeAckVariableHeader();
    this.payload = MqttSubscribeAckPayload();
  }

  /// Initializes a new instance of the MqttSubscribeAckMessage class.
  MqttSubscribeAckMessage.fromByteBuffer(MqttHeader header,
      MqttByteBuffer messageStream) {
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
        MqttSubscribeAckVariableHeader.fromByteBuffer(messageStream);
    this.payload = MqttSubscribeAckPayload.fromByteBuffer(
        header, variableHeader, messageStream);
  }

  /// Sets the message identifier on the subscribe message.
  MqttSubscribeAckMessage withMessageIdentifier(int messageIdentifier) {
    this.variableHeader.messageIdentifier = messageIdentifier;
    return this;
  }

  ///  Adds a Qos grant to the message.
  MqttSubscribeAckMessage addQosGrant(MqttQos qosGranted) {
    this.payload.addGrant(qosGranted);
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
