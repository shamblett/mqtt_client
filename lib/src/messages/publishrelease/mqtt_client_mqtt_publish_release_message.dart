/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Implementation of an MQTT Publish Release Message.
class MqttPublishReleaseMessage extends MqttMessage {
  /// Gets or sets the variable header contents. Contains extended metadata about the message
  MqttPublishReleaseVariableHeader variableHeader;

  /// Initializes a new instance of the MqttPublishReleaseMessage class.
  MqttPublishReleaseMessage() {
    this.header = MqttHeader().asType(MqttMessageType.publishRelease);
    this.variableHeader = MqttPublishReleaseVariableHeader();
  }

  /// Initializes a new instance of the MqttPublishReleaseMessage class.
  MqttPublishReleaseMessage.fromByteBuffer(
      MqttHeader header, MqttByteBuffer messageStream) {
    this.header = header;
    this.variableHeader =
        MqttPublishReleaseVariableHeader.fromByteBuffer(messageStream);
  }

  /// Writes the message to the supplied stream.
  void writeTo(MqttByteBuffer messageStream) {
    this.header.writeTo(this.variableHeader.getWriteLength(), messageStream);
    this.variableHeader.writeTo(messageStream);
  }

  /// Sets the message identifier of the MqttMessage.
  MqttPublishReleaseMessage withMessageIdentifier(int messageIdentifier) {
    this.variableHeader.messageIdentifier = messageIdentifier;
    return this;
  }

  String toString() {
    final StringBuffer sb = StringBuffer();
    sb.write(super.toString());
    sb.writeln(variableHeader.toString());
    return sb.toString();
  }
}
