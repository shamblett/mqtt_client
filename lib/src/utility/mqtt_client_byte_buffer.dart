/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of '../../mqtt_client.dart';

/// Utility class to allow stream like access to a sized byte buffer.
/// This class is in effect a cut-down implementation of the C# NET
/// System.IO class with Mqtt client specific extensions.
class MqttByteBuffer {
  /// Large payload handling.
  /// If count of bytes to read for a payload is larger than this then
  /// large payload handling is invoked.
  static const largePayload = 32767;

  /// The underlying byte buffer
  typed.Uint8Buffer? buffer;

  // The current position within the buffer.
  int _position = 0;

  /// Position
  int get position => _position;

  /// Length
  int get length => buffer!.length;

  /// Available bytes
  int get availableBytes => length - _position;

  /// Skip bytes
  set skipBytes(int bytes) => _position += bytes;

  /// The byte buffer
  MqttByteBuffer(this.buffer);

  /// From a list
  MqttByteBuffer.fromList(List<int> data) {
    buffer = typed.Uint8Buffer();
    buffer!.addAll(data);
  }

  /// Resets the position to 0
  void reset() {
    _position = 0;
  }

  /// Add a list
  void addAll(List<int> data) {
    buffer!.addAll(data);
  }

  /// Shrink the buffer
  void shrink() {
    _position < buffer!.length
        ? buffer!.removeRange(0, _position)
        : buffer!.clear();
    _position = 0;
  }

  /// Message available
  bool isMessageAvailable() {
    if (availableBytes > 0) {
      return true;
    }

    return false;
  }

  /// Reads a byte from the buffer and advances the position
  /// within the buffer by one byte, or returns -1 if at the end of the buffer.
  int readByte() {
    final tmp = buffer![_position];
    if (_position <= (length - 1)) {
      _position++;
    } else {
      return -1;
    }
    return tmp;
  }

  /// Read a short int(16 bits)
  int readShort() {
    final high = readByte();
    final low = readByte();
    return (high << 8) + low;
  }

  /// Reads a sequence of bytes from the current
  /// buffer and advances the position within the buffer
  /// by the number of bytes read.
  typed.Uint8Buffer read(int count) {
    if ((length < count) || (_position + count) > length) {
      throw Exception(
        'mqtt_client::ByteBuffer::read: The buffer does not have '
        'enough bytes for the read operation '
        'length $length, count $count, position $_position, buffer $buffer',
      );
    }
    _position += count;
    return typed.Uint8Buffer()
      ..addAll(buffer!.getRange(_position - count, _position));
  }

  /// Reads a sequence of bytes from the current
  /// buffer and advances the position within the buffer
  /// by the number of bytes read.
  ///
  /// Specifically intended for reading payload data from publish messages which can
  /// be quite large.
  typed.Uint8Buffer readPayload(int count) {
    if ((length < count) || (_position + count) > length) {
      throw Exception(
        'mqtt_client::ByteBuffer::readPayload: The buffer does not have '
        'enough bytes for the read operation '
        'length $length, count $count, position $_position, buffer $buffer',
      );
    }
    // If not a large payload use the normal buffer read method.
    if (count <= largePayload) {
      return read(count);
    }
    // See where the position is, if not 0 we can remove the range 0.._position
    // as we know we are looking for a payload.
    if (_position != 0) {
      buffer!.removeRange(0, _position);
      _position = 0;
    }
    // _position is now guaranteed to be 0 and at the start of the payload data.
    // If the length of the buffer is equal to count then just return it.
    final savedData = typed.Uint8Buffer();
    if (buffer!.length == count) {
      _position = buffer!.length;
      return typed.Uint8Buffer()..addAll(buffer!);
    } else {
      // Trailing data, save it.
      savedData.addAll(buffer!.getRange(_position + count, length).toList());
      // Remove it, leaving just the payload
      buffer!.removeRange(_position + count, length);
      // Save the payload data
      final tmp = typed.Uint8Buffer()..addAll(buffer!);
      // Clear the buffer
      buffer!.clear();
      // Restore the trailing data and set the position to zero
      buffer!.addAll(savedData);
      _position = 0;
      // Return the payload
      return tmp;
    }
  }

  /// Writes a byte to the current position in the buffer
  /// and advances the position within the buffer by one byte.
  void writeByte(int byte) {
    if (buffer!.length == _position) {
      buffer!.add(byte);
    } else {
      buffer![_position] = byte;
    }
    _position++;
  }

  /// Write a short(16 bit)
  void writeShort(int short) {
    writeByte(short >> 8);
    writeByte(short & 0xFF);
  }

  /// Writes a sequence of bytes to the current
  /// buffer and advances the position within the buffer by the number of
  /// bytes written.
  void write(typed.Uint8Buffer? buffer) {
    if (this.buffer == null) {
      this.buffer = buffer;
    } else {
      this.buffer!.addAll(buffer!);
    }
    _position = length;
  }

  /// Seek. Sets the position in the buffer. If overflow occurs
  /// the position is set to the end of the buffer.
  void seek(int seek) {
    ((seek <= length) && (seek >= 0)) ? _position = seek : _position = length;
  }

  /// Writes an MQTT string member
  void writeMqttStringM(String stringToWrite) {
    writeMqttString(this, stringToWrite);
  }

  /// Writes an MQTT string.
  /// stringStream - The stream containing the string to write.
  /// stringToWrite - The string to write.
  static void writeMqttString(
    MqttByteBuffer stringStream,
    String stringToWrite,
  ) {
    final enc = MqttEncoding();
    final stringBytes = enc.getBytes(stringToWrite);
    stringStream.write(stringBytes);
  }

  /// Reads an MQTT string from the underlying stream member
  String readMqttStringM() => MqttByteBuffer.readMqttString(this);

  /// Reads an MQTT string from the underlying stream.
  static String readMqttString(MqttByteBuffer buffer) {
    // Read and check the length
    final lengthBytes = buffer.read(2);
    final enc = MqttEncoding();
    final stringLength = enc.getCharCount(lengthBytes);
    final stringBuff = buffer.read(stringLength);
    return enc.getString(stringBuff);
  }

  @override
  String toString() {
    String tmp;
    (buffer != null && buffer!.isNotEmpty)
        ? tmp = buffer!.toList().toString()
        : tmp = 'null or empty';
    return tmp;
  }
}
