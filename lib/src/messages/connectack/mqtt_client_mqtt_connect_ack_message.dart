/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 15/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Message that indicates a connection acknowledgement.
class MqttConnectAckMessage extends MqttMessage {
  /// Initializes a new instance of the MqttConnectAckMessage class.
  /// Only called via the MqttMessage.Create operation during processing of an Mqtt message stream.
  MqttConnectAckMessage() {
    this.header = MqttHeader().asType(MqttMessageType.connectAck);
    this.variableHeader = MqttConnectAckVariableHeader();
    this.variableHeader.returnCode = MqttConnectReturnCode.connectionAccepted;
  }

  /// Gets or sets the variable header contents. Contains extended metadata about the message
  MqttConnectAckVariableHeader variableHeader;

  /// Initializes a new instance of the MqttConnectAckMessage class.
  MqttConnectAckMessage.fromByteBuffer(MqttHeader header,
      MqttByteBuffer messageStream) {
    this.header = header;
    readFrom(messageStream);
  }

  /// Reads a message from the supplied stream.
  void readFrom(MqttByteBuffer messageStream) {
    super.readFrom(messageStream);
    this.variableHeader =
        MqttConnectAckVariableHeader.fromByteBuffer(messageStream);
  }

  /// Writes a message to the supplied stream.
  void writeTo(MqttByteBuffer messageStream) {
    this.header.writeTo(variableHeader.getWriteLength(), messageStream);
    this.variableHeader.writeTo(messageStream);
  }

  /// Sets the return code of the Variable Header.
  MqttConnectAckMessage withReturnCode(MqttConnectReturnCode returnCode) {
    this.variableHeader.returnCode = returnCode;
    return this;
  }

  String toString() {
    final StringBuffer sb = StringBuffer();
    sb.write(super.toString());
    sb.writeln(variableHeader.toString());
    return sb.toString();
  }
}
