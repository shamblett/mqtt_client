/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Implementation of the variable header for an MQTT Connect message.
class MqttPublishVariableHeader extends MqttVariableHeader {
  /// Initializes a new instance of the MqttPublishVariableHeader class.
  MqttPublishVariableHeader(this.header);

  /// Initializes a new instance of the MqttPublishVariableHeader class.
  MqttPublishVariableHeader.fromByteBuffer(
      this.header, MqttByteBuffer variableHeaderStream) {
    readFrom(variableHeaderStream);
  }

  /// Standard header
  MqttHeader? header;

  /// Creates a variable header from the specified header stream.
  @override
  void readFrom(MqttByteBuffer variableHeaderStream) {
    readTopicName(variableHeaderStream);
    if (header!.qos == MqttQos.atLeastOnce ||
        header!.qos == MqttQos.exactlyOnce) {
      readMessageIdentifier(variableHeaderStream);
    }
  }

  /// Writes the variable header to the supplied stream.
  @override
  void writeTo(MqttByteBuffer variableHeaderStream) {
    writeTopicName(variableHeaderStream);
    if (header!.qos == MqttQos.atLeastOnce ||
        header!.qos == MqttQos.exactlyOnce) {
      writeMessageIdentifier(variableHeaderStream);
    }
  }

  /// Gets the length of the write data when WriteTo will be called.
  @override
  int getWriteLength() {
    var headerLength = 0;
    final enc = MqttEncoding();
    headerLength += enc.getByteCount(topicName);
    if (header!.qos == MqttQos.atLeastOnce ||
        header!.qos == MqttQos.exactlyOnce) {
      headerLength += 2;
    }
    return headerLength;
  }

  @override
  String toString() => 'Publish Variable Header: TopicName={$topicName}, '
      'MessageIdentifier={$messageIdentifier}, VH Length={$length}';
}
