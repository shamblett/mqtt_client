/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Implementation of an MQTT Publish Release Message.
class MqttPublishReleaseMessage extends MqttMessage {
  /// Initializes a new instance of the MqttPublishReleaseMessage class.
  MqttPublishReleaseMessage() {
    header = MqttHeader().asType(MqttMessageType.publishRelease);
    // Qos is specified for this message
    header!.qos = MqttQos.atLeastOnce;
    variableHeader = MqttPublishReleaseVariableHeader();
  }

  /// Initializes a new instance of the MqttPublishReleaseMessage class.
  MqttPublishReleaseMessage.fromByteBuffer(
      MqttHeader header, MqttByteBuffer messageStream) {
    this.header = header;
    variableHeader =
        MqttPublishReleaseVariableHeader.fromByteBuffer(messageStream);
  }

  /// Gets or sets the variable header contents. Contains extended
  /// metadata about the message.
  late MqttPublishReleaseVariableHeader variableHeader;

  /// Writes the message to the supplied stream.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    header!.writeTo(variableHeader.getWriteLength(), messageStream);
    variableHeader.writeTo(messageStream);
  }

  /// Sets the message identifier of the MqttMessage.
  MqttPublishReleaseMessage withMessageIdentifier(int? messageIdentifier) {
    variableHeader.messageIdentifier = messageIdentifier;
    return this;
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(super.toString());
    sb.writeln(variableHeader.toString());
    return sb.toString();
  }
}
