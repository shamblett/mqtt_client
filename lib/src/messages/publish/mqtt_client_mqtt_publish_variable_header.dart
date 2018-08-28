/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Implementation of the variable header for an MQTT Connect message.
class MqttPublishVariableHeader extends MqttVariableHeader {
  /// Stores the standard header
  MqttHeader header;

  /// Initializes a new instance of the MqttPublishVariableHeader class.
  MqttPublishVariableHeader(MqttHeader header) {
    this.header = header;
  }

  /// Initializes a new instance of the MqttPublishVariableHeader class.
  MqttPublishVariableHeader.fromByteBuffer(
      MqttHeader header, MqttByteBuffer variableHeaderStream) {
    this.header = header;
    readFrom(variableHeaderStream);
  }

  /// Creates a variable header from the specified header stream.
  void readFrom(MqttByteBuffer variableHeaderStream) {
    readTopicName(variableHeaderStream);
    if (this.header.qos == MqttQos.atLeastOnce ||
        this.header.qos == MqttQos.exactlyOnce) {
      readMessageIdentifier(variableHeaderStream);
    }
  }

  /// Writes the variable header to the supplied stream.
  void writeTo(MqttByteBuffer variableHeaderStream) {
    writeTopicName(variableHeaderStream);
    if (this.header.qos == MqttQos.atLeastOnce ||
        this.header.qos == MqttQos.exactlyOnce) {
      writeMessageIdentifier(variableHeaderStream);
    }
  }

  /// Gets the length of the write data when WriteTo will be called.
  int getWriteLength() {
    int headerLength = 0;
    final MqttEncoding enc = MqttEncoding();
    headerLength += enc.getByteCount(topicName);
    if (this.header.qos == MqttQos.atLeastOnce ||
        this.header.qos == MqttQos.exactlyOnce) {
      headerLength += 2;
    }
    return headerLength;
  }

  String toString() {
    return "Publish Variable Header: TopicName={$topicName}, MessageIdentifier={$messageIdentifier}, VH Length={$length}";
  }
}
