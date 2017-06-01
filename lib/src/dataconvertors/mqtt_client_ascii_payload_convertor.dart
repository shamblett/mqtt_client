/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Converts string data to and from the MQTT wire format
class AsciiPayloadConverter implements IPayloadConverter<String> {
  /// Processes received data and returns it as a string.
  String convertFromBytes(typed.Uint8Buffer messageData) {
    final Utf8Decoder decoder = new Utf8Decoder();
    return decoder.convert(messageData.toList());
  }

  /// Converts sent data from a string to a byte array.
  typed.Uint8Buffer convertToBytes(String data) {
    final Utf8Encoder encoder = new Utf8Encoder();
    final typed.Uint8Buffer buff = new typed.Uint8Buffer();
    buff.addAll(encoder.convert(data));
    return buff;
  }
}
