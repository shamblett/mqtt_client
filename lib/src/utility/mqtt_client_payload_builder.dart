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

  typed.Uint8Buffer get payload => _payload;

  int get length => _payload.length;

  MqttClientPayloadBuilder() {
    _payload = new typed.Uint8Buffer();
  }

  /// Add a buffer
  void addBuffer(typed.Uint8Buffer buffer) {
    _payload.addAll(buffer);
  }

  /// Add byte
  void addByte(int val) {
    final typed.Uint8Buffer tmp = new typed.Uint8Buffer(1);
    tmp.add(val);
    _payload.add(tmp.toList()[0]);
  }

  /// Add a bool, true is 1, false is 0
  void addBool(bool val) {
    val ? addByte(1) : addByte(0);
  }

/// Add a halfword, 16 bits

}
