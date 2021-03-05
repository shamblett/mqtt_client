/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Implementation of an MQTT Publish Complete Message.
class MqttPublishCompleteMessage extends MqttMessage {
  /// Initializes a new instance of the MqttPublishCompleteMessage class.
  MqttPublishCompleteMessage() {
    header = MqttHeader().asType(MqttMessageType.publishComplete);
    variableHeader = MqttPublishCompleteVariableHeader();
  }

  /// Initializes a new instance of the MqttPublishCompleteMessage class.
  MqttPublishCompleteMessage.fromByteBuffer(
      MqttHeader header, MqttByteBuffer messageStream) {
    this.header = header;
    variableHeader =
        MqttPublishCompleteVariableHeader.fromByteBuffer(messageStream);
  }

  /// Gets or sets the variable header contents. Contains extended
  /// metadata about the message
  late MqttPublishCompleteVariableHeader variableHeader;

  /// Writes the message to the supplied stream.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    header!.writeTo(variableHeader.getWriteLength(), messageStream);
    variableHeader.writeTo(messageStream);
  }

  /// Sets the message identifier of the MqttMessage.
  MqttPublishCompleteMessage withMessageIdentifier(int? messageIdentifier) {
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
