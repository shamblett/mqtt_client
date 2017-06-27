/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Enumeration used by subclasses to tell the variable header what should be read from the underlying stream.
enum readWriteFlags {
  none,
  protocolName,
  protocolVersion,
  connectFlags,
  keepAlive,
  returnCode,
  topicName,
  messageIdentifier
}

/// Represents the base class for the Variable Header portion of some MQTT Messages.
class MqttVariableHeader {
  /// The length, in bytes, consumed by the variable header.
  int length = 0;

  String protocolName;
  int protocolVersion;
  MqttConnectFlags connectFlags;

  /// Defines the maximum allowable lag, in seconds, between expected messages.
  /// The spec indicates that clients won't be disconnected until KeepAlive + 1/2 KeepAlive time period
  /// elapses.
  int keepAlive = 0;

  MqttConnectReturnCode returnCode;
  String topicName;
  int messageIdentifier;

  /// Initializes a new instance of the MqttVariableHeader class.
  MqttVariableHeader() {
    this.protocolName = "MQIsdp";
    this.protocolVersion = 3;
    this.connectFlags = new MqttConnectFlags();
  }

  /// Initializes a new instance of the <see cref="MqttVariableHeader" /> class, populating it with data from a stream.
  MqttVariableHeader.fromByteBuffer(MqttByteBuffer headerStream) {
    readFrom(headerStream);
  }

  /// Creates a variable header from the specified header stream.
  /// A subclass can override this method to do completely custom read operations
  /// if required.
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
  /// This base implementation uses the WriteFlags property that can be
  /// overridden in subclasses to determine what to read from the variable header.
  /// A subclass can override this method to do completely custom write operations
  /// if required.
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
    int headerLength = 0;
    final MqttEncoding enc = new MqttEncoding();
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

  void writeProtocolName(MqttByteBuffer stream) {
    MqttByteBuffer.writeMqttString(stream, protocolName);
  }

  void writeProtocolVersion(MqttByteBuffer stream) {
    stream.writeByte(protocolVersion);
  }

  void writeKeepAlive(MqttByteBuffer stream) {
    stream.writeShort(keepAlive);
  }

  void writeReturnCode(MqttByteBuffer stream) {
    stream.writeByte(returnCode.index);
  }

  void writeTopicName(MqttByteBuffer stream) {
    MqttByteBuffer.writeMqttString(stream, topicName.toString());
  }

  void writeMessageIdentifier(MqttByteBuffer stream) {
    stream.writeShort(messageIdentifier);
  }

  void writeConnectFlags(MqttByteBuffer stream) {
    connectFlags.writeTo(stream);
  }

  /// Read functions

  void readProtocolName(MqttByteBuffer stream) {
    protocolName = MqttByteBuffer.readMqttString(stream);
    length += protocolName.length + 2; // 2 for length short at front of string
  }

  void readProtocolVersion(MqttByteBuffer stream) {
    protocolVersion = stream.readByte();
    length++;
  }

  void readKeepAlive(MqttByteBuffer stream) {
    keepAlive = stream.readShort();
    length += 2;
  }

  void readReturnCode(MqttByteBuffer stream) {
    returnCode = MqttConnectReturnCode.values[stream.readByte()];
    length++;
  }

  void readTopicName(MqttByteBuffer stream) {
    topicName = MqttByteBuffer.readMqttString(stream);
    length += topicName.length + 2; // 2 for length short at front of string.
  }

  void readMessageIdentifier(MqttByteBuffer stream) {
    messageIdentifier = stream.readShort();
    length += 2;
  }

  void readConnectFlags(MqttByteBuffer stream) {
    connectFlags = new MqttConnectFlags.fromByteBuffer(stream);
    length += 1;
  }
}
