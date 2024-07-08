/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 15/06/2017
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt_client.dart';

/// Implementation of the variable header for an MQTT ConnectAck message.
class MqttConnectAckVariableHeader extends MqttVariableHeader {
  /// Initializes a new instance of the MqttConnectVariableHeader class.
  MqttConnectAckVariableHeader();

  /// Initializes a new instance of the MqttConnectVariableHeader class.
  MqttConnectAckVariableHeader.fromByteBuffer(super.headerStream)
      : super.fromByteBuffer();

  /// Writes the variable header for an MQTT Connect message to
  /// the supplied stream.
  @override
  void writeTo(MqttByteBuffer variableHeaderStream) =>
      super.writeTo(variableHeaderStream);

  /// Creates a variable header from the specified header stream.
  @override
  void readFrom(MqttByteBuffer variableHeaderStream) =>
      super.readFrom(variableHeaderStream);

  /// Gets the length of the write data when WriteTo will be called.
  @override
  int getWriteLength() {
    var headerLength = 0;
    final enc = MqttEncoding();
    headerLength += enc.getByteCount(protocolName);
    headerLength += 1; // protocolVersion
    headerLength += MqttConnectFlags.getWriteLength();
    headerLength += 2; // keepAlive
    return headerLength;
  }

  @override
  String toString() =>
      'Connect Variable Header: TopicNameCompressionResponse={0}, '
      'ReturnCode={$returnCode}';
}
