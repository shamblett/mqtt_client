/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Implementation of an MQTT Publish Acknowledgement Message, used to ACK a publish message that has it's QOS set to AtLeast or Exactly Once.
class MqttPublishAckMessage extends MqttMessage {
  /// Gets or sets the variable header contents. Contains extended metadata about the message
  MqttPublishAckVariableHeader variableHeader;

  /// Initializes a new instance of the MqttPublishAckMessage class.
  MqttPublishAckMessage() {
    this.header = new MqttHeader().asType(MqttMessageType.publishAck);
    this.variableHeader = new MqttPublishAckVariableHeader();
  }

  /// Initializes a new instance of the MqttPublishAckMessage class.
  MqttPublishAckMessage.fromByteBuffer(MqttHeader header,
      MqttByteBuffer messageStream) {
    this.header = header;
    this.variableHeader =
    new MqttPublishAckVariableHeader.fromByteBuffer(messageStream);
  }

  void writeTo(MqttByteBuffer messageStream) {
    this.header.writeTo(this.variableHeader.getWriteLength(), messageStream);
    this.variableHeader.writeTo(messageStream);
  }

  /// Sets the message identifier of the MqttMessage.
  MqttPublishAckMessage withMessageIdentifier(int messageIdentifier) {
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
