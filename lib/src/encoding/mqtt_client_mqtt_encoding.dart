/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Encoding implementation that can encode and decode strings
/// in the MQTT string format.
///
/// The MQTT string format is simply a pascal string with ANSI character
/// encoding. The first 2 bytes define the length of the string, and they
/// are followed by the string itself.
class MqttEncoding extends Utf8Codec {
  /// Encodes all the characters in the specified string
  /// into a sequence of bytes.
  typed.Uint8Buffer getBytes(String s) {
    _validateString(s);
    final stringBytes = typed.Uint8Buffer();
    stringBytes.add(s.length >> 8);
    stringBytes.add(s.length & 0xFF);
    stringBytes.addAll(encoder.convert(s));
    return stringBytes;
  }

  /// Decodes the bytes in the specified byte array into a string.
  String getString(typed.Uint8Buffer bytes) => decoder.convert(bytes.toList());

  ///  When overridden in a derived class, calculates the number of characters
  ///  produced by decoding all the bytes in the specified byte array.
  int getCharCount(typed.Uint8Buffer bytes) {
    if (bytes.length < 2) {
      throw Exception(
          'mqtt_client::MQTTEncoding: Length byte array must comprise 2 bytes');
    }
    return (bytes[0] << 8) + bytes[1];
  }

  /// Calculates the number of bytes produced by encoding the
  /// characters in the specified.
  int getByteCount(String chars) => getBytes(chars).length;

  /// Validates the string to ensure it doesn't contain any characters
  /// invalid within the Mqtt string format.
  static void _validateString(String s) {
    for (var i = 0; i < s.length; i++) {
      if (Protocol.version == MqttClientConstants.mqttV31ProtocolVersion) {
        if (s.codeUnitAt(i) > 0x7F) {
          throw Exception(
              'mqtt_client::MQTTEncoding: The input string has extended '
              'UTF characters, which are not supported');
        }
      }
    }
  }
}
