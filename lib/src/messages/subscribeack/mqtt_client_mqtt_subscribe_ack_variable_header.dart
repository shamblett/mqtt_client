/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt_client.dart';

/// Implementation of the variable header for an MQTT Subscribe Ack message.
class MqttSubscribeAckVariableHeader extends MqttVariableHeader {
  /// Initializes a new instance of the MqttSubscribeAckVariableHeader class.
  MqttSubscribeAckVariableHeader();

  /// Initializes a new instance of the MqttSubscribeAckVariableHeader class.
  MqttSubscribeAckVariableHeader.fromByteBuffer(MqttByteBuffer headerStream) {
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
      'SubscribeAck Variable Header: MessageIdentifier={$messageIdentifier}';
}
