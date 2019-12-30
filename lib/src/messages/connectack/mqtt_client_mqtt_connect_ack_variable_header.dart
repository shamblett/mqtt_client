/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 15/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Implementation of the variable header for an MQTT ConnectAck message.
class MqttConnectAckVariableHeader extends MqttVariableHeader {
  /// Initializes a new instance of the MqttConnectVariableHeader class.
  MqttConnectAckVariableHeader();

  /// Initializes a new instance of the MqttConnectVariableHeader class.
  MqttConnectAckVariableHeader.fromByteBuffer(MqttByteBuffer headerStream)
      : super.fromByteBuffer(headerStream);

  /// Writes the variable header for an MQTT Connect message to
  /// the supplied stream.
  @override
  void writeTo(MqttByteBuffer variableHeaderStream) {
    // Unused additional 'compression' byte used within the variable
    // header acknowledgement.
    variableHeaderStream.writeByte(0);
    writeReturnCode(variableHeaderStream);
  }

  /// Creates a variable header from the specified header stream.
  @override
  void readFrom(MqttByteBuffer variableHeaderStream) {
    // Unused additional 'compression' byte used within the variable
    // header acknowledgement.
    variableHeaderStream.readByte();
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
      'Connect Variable Header: TopicNameCompressionResponse={0}, '
      'ReturnCode={$returnCode}';
}
