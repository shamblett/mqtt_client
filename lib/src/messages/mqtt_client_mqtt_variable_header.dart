/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Enumeration used by subclasses to tell the variable header what
/// should be read from the underlying stream.
enum MqttReadWriteFlags {
  /// Nothing
  none,

  /// Protocol name
  protocolName,

  /// Protocol version
  protocolVersion,

  /// Connect flags
  connectFlags,

  /// Keep alive
  keepAlive,

  /// Return code
  returnCode,

  /// Topic name
  topicName,

  /// Message identifier
  messageIdentifier
}

/// Represents the base class for the Variable Header portion
/// of some MQTT Messages.
class MqttVariableHeader {
  /// Initializes a new instance of the MqttVariableHeader class.
  MqttVariableHeader() {
    protocolName = Protocol.name;
    protocolVersion = Protocol.version;
    connectFlags = MqttConnectFlags();
  }

  /// Initializes a new instance of the MqttVariableHeader class,
  /// populating it with data from a stream.
  MqttVariableHeader.fromByteBuffer(MqttByteBuffer headerStream) {
    readFrom(headerStream);
  }

  /// The length, in bytes, consumed by the variable header.
  int length = 0;

  /// Protocol name
  String protocolName = '';

  /// Protocol version
  int protocolVersion = 0;

  /// Conenct flags
  late MqttConnectFlags connectFlags;

  /// Defines the maximum allowable lag, in seconds, between expected messages.
  /// The spec indicates that clients won't be disconnected until KeepAlive + 1/2 KeepAlive time period
  /// elapses.
  int keepAlive = 0;

  /// Return code
  MqttConnectReturnCode returnCode = MqttConnectReturnCode.brokerUnavailable;

  /// Topic name
  String topicName = '';

  /// Message identifier
  int? messageIdentifier = 0;

  /// Encoder
  final MqttEncoding _enc = MqttEncoding();

  /// Creates a variable header from the specified header stream.
  /// A subclass can override this method to do completely
  /// custom read operations if required.
  void readFrom(MqttByteBuffer variableHeaderStream) {
    readProtocolName(variableHeaderStream);
    readProtocolVersion(variableHeaderStream);
    readConnectFlags(variableHeaderStream);
    readKeepAlive(variableHeaderStream);
    readReturnCode(variableHeaderStream);
    readTopicName(variableHeaderStream);
    readMessageIdentifier(variableHeaderStream);
  }

  /// Writes the variable header to the supplied stream.
  /// A subclass can override this method to do completely
  /// custom write operations if required.
  void writeTo(MqttByteBuffer variableHeaderStream) {
    writeProtocolName(variableHeaderStream);
    writeProtocolVersion(variableHeaderStream);
    writeConnectFlags(variableHeaderStream);
    writeKeepAlive(variableHeaderStream);
    writeReturnCode(variableHeaderStream);
    writeTopicName(variableHeaderStream);
    writeMessageIdentifier(variableHeaderStream);
  }

  /// Gets the length of the write data when WriteTo will be called.
  /// A subclass that overrides writeTo must also overwrite this method.
  int getWriteLength() {
    var headerLength = 0;
    final enc = MqttEncoding();
    headerLength += enc.getByteCount(protocolName);
    headerLength += 1; // protocolVersion
    headerLength += MqttConnectFlags.getWriteLength();
    headerLength += 2; // keepAlive
    headerLength += 1; // returnCode
    headerLength += enc.getByteCount(topicName.toString());
    headerLength += 2; // MessageIdentifier
    return headerLength;
  }

  /// Write functions

  /// Protocol name
  void writeProtocolName(MqttByteBuffer stream) {
    MqttByteBuffer.writeMqttString(stream, protocolName);
  }

  /// Protocol version
  void writeProtocolVersion(MqttByteBuffer stream) {
    stream.writeByte(protocolVersion);
  }

  /// Keep alive
  void writeKeepAlive(MqttByteBuffer stream) {
    stream.writeShort(keepAlive);
  }

  /// Return code
  void writeReturnCode(MqttByteBuffer stream) {
    stream.writeByte(returnCode.index);
  }

  /// Topic name
  void writeTopicName(MqttByteBuffer stream) {
    MqttByteBuffer.writeMqttString(stream, topicName.toString());
  }

  /// Message identifier
  void writeMessageIdentifier(MqttByteBuffer stream) {
    stream.writeShort(messageIdentifier!);
  }

  /// Connect flags
  void writeConnectFlags(MqttByteBuffer stream) {
    connectFlags.writeTo(stream);
  }

  /// Read functions

  /// Protocol name
  void readProtocolName(MqttByteBuffer stream) {
    protocolName = MqttByteBuffer.readMqttString(stream);
    length += protocolName.length + 2; // 2 for length short at front of string
  }

  /// Protocol version
  void readProtocolVersion(MqttByteBuffer stream) {
    protocolVersion = stream.readByte();
    length++;
  }

  /// Keep alive
  void readKeepAlive(MqttByteBuffer stream) {
    keepAlive = stream.readShort();
    length += 2;
  }

  /// Return code
  void readReturnCode(MqttByteBuffer stream) {
    returnCode = MqttConnectReturnCode.values[stream.readByte()];
    length++;
  }

  /// Topic name
  void readTopicName(MqttByteBuffer stream) {
    topicName = MqttByteBuffer.readMqttString(stream);
    // If the protocol si V311 allow extended UTF8 characters
    if (Protocol.version == MqttClientConstants.mqttV311ProtocolVersion) {
      length += _enc.getByteCount(topicName);
    } else {
      length = topicName.length + 2; // 2 for length short at front of string.
    }
  }

  /// Message identifier
  void readMessageIdentifier(MqttByteBuffer stream) {
    messageIdentifier = stream.readShort();
    length += 2;
  }

  /// Connect flags
  void readConnectFlags(MqttByteBuffer stream) {
    connectFlags = MqttConnectFlags.fromByteBuffer(stream);
    length += 1;
  }
}
