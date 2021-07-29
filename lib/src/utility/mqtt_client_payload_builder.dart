/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 18/04/2018
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Utility class to assist with the building of message topic payloads.
/// Implements the builder pattern, i.e. returns itself to allow chaining.
class MqttClientPayloadBuilder {
  /// Construction
  MqttClientPayloadBuilder() {
    _payload = typed.Uint8Buffer();
  }

  typed.Uint8Buffer? _payload;

  /// Payload
  typed.Uint8Buffer? get payload => _payload;

  /// Length
  int get length => _payload!.length;

  /// Add a buffer
  MqttClientPayloadBuilder addBuffer(typed.Uint8Buffer buffer) {
    _payload!.addAll(buffer);
    return this;
  }

  /// Add byte, this will overflow on values > 2**8-1
  MqttClientPayloadBuilder addByte(int val) {
    _payload!.add(val);
    return this;
  }

  /// Add a bool, true is 1, false is 0
  MqttClientPayloadBuilder addBool({required bool val}) {
    val ? addByte(1) : addByte(0);
    return this;
  }

  /// Add a half word, 16 bits, this will overflow on values > 2**16-1
  MqttClientPayloadBuilder addHalf(int val) {
    final tmp = Uint16List.fromList(<int>[val]);
    _payload!.addAll(tmp.buffer.asInt8List());
    return this;
  }

  /// Add a word, 32 bits, this will overflow on values > 2**32-1
  MqttClientPayloadBuilder addWord(int val) {
    final tmp = Uint32List.fromList(<int>[val]);
    _payload!.addAll(tmp.buffer.asInt8List());
    return this;
  }

  /// Add a long word, 64 bits or a Dart int
  MqttClientPayloadBuilder addInt(int val) {
    final tmp = Uint64List.fromList(<int>[val]);
    _payload!.addAll(tmp.buffer.asInt8List());
    return this;
  }

  /// Add a standard Dart string
  MqttClientPayloadBuilder addString(String val) {
    addUTF16String(val);
    return this;
  }

  /// Add a UTF16 string, note Dart natively encodes strings as UTF16
  MqttClientPayloadBuilder addUTF16String(String val) {
    for (final codeUnit in val.codeUnits) {
      if (codeUnit <= 255 && codeUnit >= 0) {
        _payload!.add(codeUnit);
      } else {
        addHalf(codeUnit);
      }
    }
    return this;
  }

  /// Add a UTF8 string
  MqttClientPayloadBuilder addUTF8String(String val) {
    const encoder = Utf8Encoder();
    _payload!.addAll(encoder.convert(val));
    return this;
  }

  /// Add a 32 bit double
  MqttClientPayloadBuilder addHalfDouble(double val) {
    final tmp = Float32List.fromList(<double>[val]);
    _payload!.addAll(tmp.buffer.asInt8List());
    return this;
  }

  /// Add a 64 bit double
  MqttClientPayloadBuilder addDouble(double val) {
    final tmp = Float64List.fromList(<double>[val]);
    _payload!.addAll(tmp.buffer.asInt8List());
    return this;
  }

  /// Clear the buffer
  MqttClientPayloadBuilder clear() {
    _payload!.clear();
    return this;
  }
}
