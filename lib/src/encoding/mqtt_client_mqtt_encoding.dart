/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Encoding implementation that can encode and decode strings in the MQTT string format.
///
/// The MQTT string format is simply a pascal string with ANSI character encoding. The first 2 bytes define
/// the length of the string, and they are followed by the string itself.
class MQTTEncoding extends Utf8Codec {
  /// Encodes all the characters in the specified string into a sequence of bytes.
  typed.Uint8Buffer getBytes(String s) {
    _validateString(s);
    final typed.Uint8Buffer stringBytes = new typed.Uint8Buffer();
    stringBytes.add(s.length >> 8);
    stringBytes.add(s.length & 0xFF);
    stringBytes.addAll(encoder.convert(s));
    return stringBytes;
  }

  /// Decodes the bytes in the specified byte array into a string.
  String getString(typed.Uint8Buffer bytes) {
    return decoder.convert(bytes.toList());
  }

  /// Validates the string to ensure it doesn't contain any characters invalid within the Mqtt string format.
  static void _validateString(String s) {
    for (int i = 0; i < s.length; i++) {
      if (s.codeUnitAt(i) > 0x7F) {
        throw new Exception(
            "mqtt_client::MQTTEncoding: The input string has extended "
                "UTF characters, which are not supported");
      }
    }
  }
}
