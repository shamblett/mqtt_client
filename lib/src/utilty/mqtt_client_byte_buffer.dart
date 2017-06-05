/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Utility class to allow stream like access to a sized byte buffer.
class ByteBuffer {
  ByteBuffer(this._buffer) {
    _length = _buffer.length;
  }

  int _index = 0;

  int get currentIndex => _index;

  void reset() {
    _index = 0;
  }

  int _length;

  int get length => _length;

  typed.Uint8Buffer _buffer;

  typed.Uint8Buffer get buffer => _buffer;

  /// Read a byte. If the index would overflow the last byte
  /// is returned.
  int readByte() {
    final int tmp = _buffer[_index];
    if (_index < _buffer.length) {
      _index++;
    }
    return tmp;
  }

  /// Write a byte.
  void writeByte(int byte) {
    _buffer.add(byte);
    _index++;
  }

  /// Seek to. Increments the index to the seek value. If the index
  /// would overflow the buffer the last byte is selected.
  void seekTo(int seek) {
    if ((seek <= _length) && (seek >= 0)) {
      _index = seek;
    } else
      _index = _length;
  }

  /// Write(replace) the current buffer
  void write(typed.Uint8Buffer buffer) {
    _buffer = buffer;
    _length = _buffer.length;
    _index = 0;
  }
}
