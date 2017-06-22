/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Implementation of the variable header for an MQTT Unsubscribe Ack message.
class MqttUnsubscribeAckVariableHeader extends MqttVariableHeader {
  /// Initializes a new instance of the MqttUnsubscribeAckVariableHeader class.
  MqttUnsubscribeAckVariableHeader();

  /// Initializes a new instance of the MqttUnsubscribeAckVariableHeader class.
  MqttUnsubscribeAckVariableHeader.fromByteBuffer(MqttByteBuffer headerStream) {
    readFrom(headerStream);
  }

  /// Creates a variable header from the specified header stream.
  void readFrom(MqttByteBuffer variableHeaderStream) {
    readMessageIdentifier(variableHeaderStream);
  }

  /// Writes the variable header to the supplied stream.
  void writeTo(MqttByteBuffer variableHeaderStream) {
    writeMessageIdentifier(variableHeaderStream);
  }

  /// Gets the length of the write data when WriteTo will be called.
  int getWriteLength() {
    return 2;
  }

  String toString() {
    return "UnsubscribeAck Variable Header: MessageIdentifier={$messageIdentifier}";
  }
}
