/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 15/06/2017
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt_client.dart';

/// Implementation of the variable header for an MQTT ConnectAck message.
class MqttConnectAckVariableHeader extends MqttVariableHeader {
  // Session present flag.
  // Only available for the 3.1.1 protocol, for 3.1 this is always false.
  bool _sessionPresent = false;

  bool get sessionPresent => _sessionPresent;
  set sessionPresent(bool present) {
    if (Protocol.version == MqttClientConstants.mqttV311ProtocolVersion) {
      _sessionPresent = present;
    }
  }

  /// Initializes a new instance of the MqttConnectVariableHeader class.
  MqttConnectAckVariableHeader();

  /// Initializes a new instance of the MqttConnectVariableHeader class.
  MqttConnectAckVariableHeader.fromByteBuffer(super.headerStream)
    : super.fromByteBuffer();

  /// Writes the variable header for an MQTT Connect message to
  /// the supplied stream.
  @override
  void writeTo(MqttByteBuffer variableHeaderStream) {
    sessionPresent
        ? variableHeaderStream.writeByte(1)
        : variableHeaderStream.writeByte(0);
    writeReturnCode(variableHeaderStream);
  }

  /// Creates a variable header from the specified header stream.
  @override
  void readFrom(MqttByteBuffer variableHeaderStream) {
    final ackConnectFlags = variableHeaderStream.readByte();
    if (Protocol.version == MqttClientConstants.mqttV311ProtocolVersion) {
      sessionPresent = ackConnectFlags == 1;
    }
    readReturnCode(variableHeaderStream);
  }

  /// Gets the length of the write data when WriteTo will be called.
  /// This method is overriden by the ConnectAckVariableHeader because the
  /// variable header of this message type, for some reason, contains an extra
  /// byte that is not present in the variable header spec, meaning we have to
  /// do some custom serialization and deserialization.
  @override
  int getWriteLength() => 2;

  @override
  String toString() =>
      'Connect Variable Header: SessionPresent={$sessionPresent}, '
      'ReturnCode={$returnCode}';
}
