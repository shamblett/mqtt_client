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

  /// Write(replace) the current buffer
  void write(typed.Uint8Buffer buffer) {
    _buffer = buffer;
    _length = _buffer.length;
    _index = 0;
  }
}