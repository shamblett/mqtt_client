/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt_client.dart';

/// Implementation of an MQTT Publish Received Message.
class MqttPublishReceivedMessage extends MqttMessage {
  /// Initializes a new instance of the MqttPublishReceivedMessage class.
  MqttPublishReceivedMessage() {
    header = MqttHeader().asType(MqttMessageType.publishReceived);
    variableHeader = MqttPublishReceivedVariableHeader();
  }

  /// Initializes a new instance of the MqttPublishReceivedMessage class.
  MqttPublishReceivedMessage.fromByteBuffer(
      MqttHeader header, MqttByteBuffer messageStream) {
    this.header = header;
    variableHeader =
        MqttPublishReceivedVariableHeader.fromByteBuffer(messageStream);
  }

  /// Gets or sets the variable header contents. Contains extended
  /// metadata about the message.
  late MqttPublishReceivedVariableHeader variableHeader;

  /// Writes the message to the supplied stream.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    header!.writeTo(variableHeader.getWriteLength(), messageStream);
    variableHeader.writeTo(messageStream);
  }

  /// Sets the message identifier of the MqttMessage.
  MqttPublishReceivedMessage withMessageIdentifier(int? messageIdentifier) {
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
