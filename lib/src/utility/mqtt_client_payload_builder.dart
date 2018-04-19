/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 18/04/2018
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Utility class to assist with the build in of message topic payloads.
class MqttClientPayloadBuilder {
  typed.Uint8Buffer _payload;

  MqttClientPayloadBuilder() {
    _payload = new typed.Uint8Buffer();
  }

  typed.Uint8Buffer get payload => _payload;

  int get length => _payload.length;

  /// Add a buffer
  void addBuffer(typed.Uint8Buffer buffer) {
    _payload.addAll(buffer);
  }

  /// Add byte, this will overflow on values > 2**8-1
  void addByte(int val) {
    _payload.add(val);
  }

  /// Add a bool, true is 1, false is 0
  void addBool(bool val) {
    val ? addByte(1) : addByte(0);
  }

  /// Add a halfword, 16 bits, this will overflow on values > 2**16-1
  void addHalf(int val) {
    final Uint16List tmp = new Uint16List.fromList([val]);
    _payload.addAll(tmp.buffer.asInt8List());
  }

  /// Add a word, 32 bits, this will overflow on values > 2**32-1
  void addWord(int val) {
    final Uint32List tmp = new Uint32List.fromList([val]);
    _payload.addAll(tmp.buffer.asInt8List());
  }

  /// Add a long word, 64 bits or a Dart int
  void addInt(int val) {
    final Uint64List tmp = new Uint64List.fromList([val]);
    _payload.addAll(tmp.buffer.asInt8List());
  }

  /// Add a UTF8 string
  void addString(String val) {
    _payload.addAll(val.codeUnits);
  }

  /// Add a UTF16 string
  void addUTF16String(String val) {
    addHalf(val.codeUnits[0]);
    addHalf(val.codeUnits[1]);
  }

  /// Add a 32 bit double
  void addHalfDouble(double val) {
    final Float32List tmp = new Float32List.fromList([val]);
    _payload.addAll(tmp.buffer.asInt8List());
  }

  /// Add a 64 bit double
  void addDouble(double val) {
    final Float64List tmp = new Float64List.fromList([val]);
    _payload.addAll(tmp.buffer.asInt8List());
  }
}
