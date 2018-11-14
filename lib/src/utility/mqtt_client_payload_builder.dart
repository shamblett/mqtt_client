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

  /// Construction
  MqttClientPayloadBuilder() {
    _payload = typed.Uint8Buffer();
  }

  /// Payload
  typed.Uint8Buffer get payload => _payload;

  /// Length
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
  void addBool({bool val}) {
    val ? addByte(1) : addByte(0);
  }

  /// Add a halfword, 16 bits, this will overflow on values > 2**16-1
  void addHalf(int val) {
    final Uint16List tmp = Uint16List.fromList(<int>[val]);
    _payload.addAll(tmp.buffer.asInt8List());
  }

  /// Add a word, 32 bits, this will overflow on values > 2**32-1
  void addWord(int val) {
    final Uint32List tmp = Uint32List.fromList(<int>[val]);
    _payload.addAll(tmp.buffer.asInt8List());
  }

  /// Add a long word, 64 bits or a Dart int
  void addInt(int val) {
    final Uint64List tmp = Uint64List.fromList(<int>[val]);
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
    final Float32List tmp = Float32List.fromList(<double>[val]);
    _payload.addAll(tmp.buffer.asInt8List());
  }

  /// Add a 64 bit double
  void addDouble(double val) {
    final Float64List tmp = Float64List.fromList(<double>[val]);
    _payload.addAll(tmp.buffer.asInt8List());
  }
}
