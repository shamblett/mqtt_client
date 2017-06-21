/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Implementation of an MQTT Publish Complete Message.
class MqttPublishCompleteMessage extends MqttMessage {
  /// Gets or sets the variable header contents. Contains extended metadata about the message
  MqttPublishCompleteVariableHeader variableHeader;

  /// Initializes a new instance of the MqttPublishCompleteMessage class.
  MqttPublishCompleteMessage() {
    this.header = new MqttHeader().asType(MqttMessageType.publishComplete);
    this.variableHeader = new MqttPublishCompleteVariableHeader();
  }

  /// Initializes a new instance of the MqttPublishCompleteMessage class.
  MqttPublishCompleteMessage.fromByteBuffer(MqttHeader header,
      MqttByteBuffer messageStream) {
    this.header = header;
    this.variableHeader =
    new MqttPublishCompleteVariableHeader.fromByteBuffer(messageStream);
  }

  /// Writes the message to the supplied stream.
  void writeTo(MqttByteBuffer messageStream) {
    this.header.writeTo(this.variableHeader.getWriteLength(), messageStream);
    this.variableHeader.writeTo(messageStream);
  }

  /// Sets the message identifier of the MqttMessage.
  MqttPublishCompleteMessage withMessageIdentifier(int messageIdentifier) {
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
