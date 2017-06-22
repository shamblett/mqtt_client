/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Implementation of an MQTT Unsubscribe Ack Message.
class MqttUnsubscribeAckMessage extends MqttMessage {
  /// Gets or sets the variable header contents. Contains extended metadata about the message
  MqttUnsubscribeAckVariableHeader variableHeader;

  /// Initializes a new instance of the MqttUnsubscribeAckMessage class.
  MqttUnsubscribeAckMessage() {
    this.header = new MqttHeader().asType(MqttMessageType.unsubscribeAck);
    this.variableHeader = new MqttUnsubscribeAckVariableHeader();
  }

  /// Initializes a new instance of the MqttUnsubscribeAckMessage class.
  MqttUnsubscribeAckMessage.fromByteBuffer(MqttHeader header,
      MqttByteBuffer messageStream) {
    this.header = header;
    readFrom(messageStream);
  }

  /// Writes the message to the supplied stream.
  void writeTo(MqttByteBuffer messageStream) {
    this.header.writeTo(this.variableHeader.getWriteLength(), messageStream);
    this.variableHeader.writeTo(messageStream);
  }

  /// Reads a message from the supplied stream.
  void readFrom(MqttByteBuffer messageStream) {
    this.variableHeader =
    new MqttUnsubscribeAckVariableHeader.fromByteBuffer(messageStream);
  }

  /// Sets the message identifier on the subscribe message.
  MqttUnsubscribeAckMessage withMessageIdentifier(int messageIdentifier) {
    this.variableHeader.messageIdentifier = messageIdentifier;
    return this;
  }

  String toString() {
    final StringBuffer sb = new StringBuffer();
    sb.write(super.toString());
    sb.writeln(variableHeader.toString());
    return sb.toString();
  }
}
