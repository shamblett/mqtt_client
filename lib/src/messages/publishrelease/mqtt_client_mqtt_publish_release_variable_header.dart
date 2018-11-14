/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Implementation of the variable header for an MQTT Publish Release message.
class MqttPublishReleaseVariableHeader extends MqttVariableHeader {
  /// Initializes a new instance of the MqttPublishReleaseVariableHeader class.
  MqttPublishReleaseVariableHeader();

  /// Initializes a new instance of the MqttPublishReleaseVariableHeader class.
  MqttPublishReleaseVariableHeader.fromByteBuffer(MqttByteBuffer headerStream) {
    readFrom(headerStream);
  }

  /// Creates a variable header from the specified header stream.
  @override
  void readFrom(MqttByteBuffer variableHeaderStream) {
    readMessageIdentifier(variableHeaderStream);
  }

  /// Writes the variable header to the supplied stream.
  @override
  void writeTo(MqttByteBuffer variableHeaderStream) {
    writeMessageIdentifier(variableHeaderStream);
  }

  /// Gets the length of the write data when WriteTo will be called.
  @override
  int getWriteLength() => 2;

  @override
  String toString() =>
      'PublishRelease Variable Header: MessageIdentifier={$messageIdentifier}';
}
