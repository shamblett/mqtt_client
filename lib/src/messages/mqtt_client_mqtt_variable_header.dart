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
  int length;

  String protocolName;
  int protocolVersion;
  MqttConnectFlags connectFlags;

  /// Defines the maximum allowable lag, in seconds, between expected messages.
  /// The spec indicates that clients won't be disconnected until KeepAlive + 1/2 KeepAlive time period
  /// elapses.
  int keepAlive;

  MqttConnectReturnCode returnCode;
  String topicName;
  int messageIdentifier;

  /// Initializes a new instance of the MqttVariableHeader class.
  MqttVariableHeader() {
    this.protocolName = "MQIsdp";
    this.protocolVersion = 3;
    this.connectFlags = new MqttConnectFlags();
  }

  /// Gets the Read Flags used during message deserialization
  readWriteFlags readFlags() {
    return readWriteFlags.none;
  }

  /// Gets the write flags used during message serialization
  readWriteFlags writeFlags() {
    return readWriteFlags.none;
  }

  /// Creates a variable header from the specified header stream.
  /// This base implementation uses the ReadFlags property that can be
  /// overridden in subclasses to determine what to read from the variable header.
  /// A subclass can override this method to do completely custom read operations
  /// if required.
  /*void readFrom(ByteBuffer variableHeaderStream) {
    if ((readFlags() & readWriteFlags.protocolName) ==
        readWriteFlags.protocolName) {
      ReadProtocolName(variableHeaderStream);
    }
    if ((ReadFlags & ReadWriteFlags.ProtocolVersion) ==
        ReadWriteFlags.ProtocolVersion) {
      ReadProtocolVersion(variableHeaderStream);
    }
    if ((ReadFlags & ReadWriteFlags.ConnectFlags) ==
        ReadWriteFlags.ConnectFlags) {
      ReadConnectFlags(variableHeaderStream);
    }
    if ((ReadFlags & ReadWriteFlags.KeepAlive) == ReadWriteFlags.KeepAlive) {
      ReadKeepAlive(variableHeaderStream);
    }
    if ((ReadFlags & ReadWriteFlags.ReturnCode) == ReadWriteFlags.ReturnCode) {
      ReadReturnCode(variableHeaderStream);
    }
    if ((ReadFlags & ReadWriteFlags.TopicName) == ReadWriteFlags.TopicName) {
      ReadTopicName(variableHeaderStream);
    }
    if ((ReadFlags & ReadWriteFlags.MessageIdentifier) ==
        ReadWriteFlags.MessageIdentifier) {
      ReadMessageIdentifier(variableHeaderStream);
    }
  }*/

  void writeProtocolName(ByteBuffer stream) {
    ByteBuffer.writeMqttString(stream, protocolName);
  }

  void writeProtocolVersion(ByteBuffer stream) {
    stream.writeByte(protocolVersion);
  }

  void writeKeepAlive(ByteBuffer stream) {
    stream.writeShort(keepAlive);
  }

  void writeReturnCode(ByteBuffer stream) {
    stream.writeByte(returnCode.index);
  }

  void writeTopicName(ByteBuffer stream) {
    ByteBuffer.writeMqttString(stream, topicName.toString());
  }

  void writeMessageIdentifier(ByteBuffer stream) {
    stream.writeShort(messageIdentifier);
  }

  void writeConnectFlags(ByteBuffer stream) {
    connectFlags.writeTo(stream);
  }

  void readProtocolName(ByteBuffer stream) {
    protocolName = ByteBuffer.readMqttString(stream);
    length += protocolName.length + 2; // 2 for length short at front of string
  }

  void readProtocolVersion(ByteBuffer stream) {
    protocolVersion = stream.readByte();
    length++;
  }

  void readKeepAlive(ByteBuffer stream) {
    keepAlive = stream.readShort();
    length += 2;
  }

  void readReturnCode(ByteBuffer stream) {
    returnCode = MqttConnectReturnCode.values[stream.readByte()];
    length++;
  }

  void readTopicName(ByteBuffer stream) {
    topicName = ByteBuffer.readMqttString(stream);
    length += topicName.length + 2; // 2 for length short at front of string.
  }

  void readMessageIdentifier(ByteBuffer stream) {
    messageIdentifier = stream.readShort();
    length += 2;
  }

  void readConnectFlags(ByteBuffer stream) {
    connectFlags = new MqttConnectFlags.fromByteBuffer(stream);
    length += 1;
  }
}
