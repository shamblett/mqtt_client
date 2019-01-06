/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 18/04/2018
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Utility class to assist with the build in of message topic payloads.
class MqttClientPayloadBuilder {
  /// Construction
  MqttClientPayloadBuilder() {
    _payload = typed.Uint8Buffer();
  }

  typed.Uint8Buffer _payload;

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
    _payload.addAll(stringToUTF8(val));
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

/// Convert strings to utf8
typed.Uint8Buffer stringToUTF8(String input) {
  final typed.Uint8Buffer output = typed.Uint8Buffer();

  for (int i = 0; i < input.length; i++) {
    int charCode = input.codeUnitAt(i);

    // Check for a surrogate pair.
    if (0xd800 <= charCode && charCode <= 0xdbff) {
      final int lowCharCode = input.codeUnitAt(++i);
      if (lowCharCode == null) {
        throw Exception(
            'mqtt_client::stringToUTF8: Malformed Unicode $charCode $lowCharCode');
      }

      charCode = ((charCode - 0xd800) << 10) + (lowCharCode - 0xdc00) + 0x10000;
    }

    if (charCode <= 0x7f) {
      output.add(charCode);
    } else if (charCode <= 0x7ff) {
      output.add(((charCode >> 6) & 0x1f) | 0xc0);
      output.add((charCode & 0x3f) | 0x80);
    } else if (charCode <= 0xffff) {
      output.add(((charCode >> 12) & 0x0f) | 0xe0);
      output.add(((charCode >> 6) & 0x3f) | 0x80);
      output.add((charCode & 0x3f) | 0x80);
    } else {
      output.add(((charCode >> 18) & 0x07) | 0xf0);
      output.add(((charCode >> 12) & 0x3f) | 0x80);
      output.add(((charCode >> 6) & 0x3f) | 0x80);
      output.add((charCode & 0x3f) | 0x80);
    }
  }

  return output;
}
