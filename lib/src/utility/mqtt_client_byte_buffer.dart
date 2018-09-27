/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Utility class to allow stream like access to a sized byte buffer.
/// This class is in effect a cut-down implementation of the C# NET
/// System.IO class with Mqtt client specific extensions.
class MqttByteBuffer {
  /// The current position within the buffer.
  int _position = 0;

  /// A value representing the length of the stream in bytes.
  int _length;

  /// The underlying byte buffer
  typed.Uint8Buffer _buffer;

  MqttByteBuffer(this._buffer) {
    _length = _buffer.length;
  }


  MqttByteBuffer.fromList(List<int> data) {
    this._buffer = typed.Uint8Buffer();
    this._buffer.addAll(data);
    _length = _buffer.length;
  }

  int get position => _position;

  int get length => _length;

  int get availableBytes => _length - _position;

  typed.Uint8Buffer get buffer => _buffer;

  set buffer(typed.Uint8Buffer buff) => _buffer = buff;

  /// Resets the position to 0
  void reset() {
    _position = 0;
  }

  void skipBytes(int bytes){
    _position += bytes;
  }

  void addAll(List<int> data){
    this._buffer.addAll(data);
    _length += data.length;
  }

  void shrink(){
    this._buffer.removeRange(0, _position);
    _length -= _position;
    _position = 0;
  }

  bool isMessageAvailable(){
    if(availableBytes > 0)
      return true;

    return false;
  }

  // Reads a byte from the buffer and advances the position within the buffer by one
  // byte, or returns -1 if at the end of the buffer.
  int readByte() {
    final int tmp = _buffer[_position];
    if (_position <= (_length - 1)) {
      _position++;
    } else {
      return -1;
    }
    return tmp;
  }

  /// Read a short int(16 bits)
  int readShort() {
    final int high = readByte();
    final int low = readByte();
    return (high << 8) + low;
  }

  /// Reads a sequence of bytes from the current
  /// buffer and advances the position within the buffer by the number of bytes read.
  typed.Uint8Buffer read(int count) {
    if ((_length < count) || (_position + count) > _length) {
      throw Exception(
          "mqtt_client::ByteBuffer: The buffer did not have enough bytes for the read operation "
          "length $_length, count $count, position $_position");
    }
    final typed.Uint8Buffer tmp = typed.Uint8Buffer();
    tmp.addAll(_buffer.getRange(_position, _position + count));
    _position += count;
    final typed.Uint8Buffer tmp2 = typed.Uint8Buffer();
    tmp2.addAll(tmp);
    return tmp2;
  }

  /// Writes a byte to the current position in the buffer and advances the position
  //  within the buffer by one byte.
  void writeByte(int byte) {
    if (_length == _position) {
      _buffer.add(byte);
      _length++;
    } else {
      _buffer[_position] = byte;
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
  void write(typed.Uint8Buffer buffer) {
    if (_buffer == null) {
      _buffer = buffer;
    } else {
      _buffer.addAll(buffer);
    }
    _length = _buffer.length;
    _position = _length;
  }

  /// Seek. Sets the position in the buffer. If overflow occurs
  /// the position is set to the end of the buffer.
  void seek(int seek) {
    if ((seek <= _length) && (seek >= 0)) {
      _position = seek;
    } else
      _position = _length;
  }

  /// Writes an MQTT string member
  void writeMqttStringM(String stringToWrite) {
    writeMqttString(this, stringToWrite);
  }

  /// Writes an MQTT string.
  /// stringStream - The stream containing the string to write.
  /// stringToWrite - The string to write.
  static void writeMqttString(
      MqttByteBuffer stringStream, String stringToWrite) {
    final MqttEncoding enc = MqttEncoding();
    final typed.Uint8Buffer stringBytes = enc.getBytes(stringToWrite);
    stringStream.write(stringBytes);
  }

  /// Reads an MQTT string from the underlying stream member
  String readMqttStringM() {
    return MqttByteBuffer.readMqttString(this);
  }

  /// Reads an MQTT string from the underlying stream.
  static String readMqttString(MqttByteBuffer buffer) {
    // Read and check the length
    final typed.Uint8Buffer lengthBytes = buffer.read(2);
    final MqttEncoding enc = MqttEncoding();
    final int stringLength = enc.getCharCount(lengthBytes);
    final typed.Uint8Buffer stringBuff = buffer.read(stringLength);
    return enc.getString(stringBuff);
  }
}
