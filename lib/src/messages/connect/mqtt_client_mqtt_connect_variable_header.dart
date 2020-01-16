/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Implementation of the variable header for an MQTT Connect message.
class MqttConnectVariableHeader extends MqttVariableHeader {
  /// Initializes a new instance of the MqttConnectVariableHeader class.
  MqttConnectVariableHeader();

  /// Initializes a new instance of the MqttConnectVariableHeader class.
  MqttConnectVariableHeader.fromByteBuffer(MqttByteBuffer headerStream)
      : super.fromByteBuffer(headerStream);

  /// Creates a variable header from the specified header stream.
  @override
  void readFrom(MqttByteBuffer variableHeaderStream) {
    readProtocolName(variableHeaderStream);
    readProtocolVersion(variableHeaderStream);
    readConnectFlags(variableHeaderStream);
    readKeepAlive(variableHeaderStream);
  }

  /// Writes the variable header to the supplied stream.
  @override
  void writeTo(MqttByteBuffer variableHeaderStream) {
    writeProtocolName(variableHeaderStream);
    writeProtocolVersion(variableHeaderStream);
    writeConnectFlags(variableHeaderStream);
    writeKeepAlive(variableHeaderStream);
  }

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
  String toString() => 'Connect Variable Header: ProtocolName=$protocolName, '
      'ProtocolVersion=$protocolVersion, '
      'ConnectFlags=${connectFlags.toString()}, '
      'KeepAlive=$keepAlive';
}
