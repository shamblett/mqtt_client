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

  ///
  void addByte(int val) {
    _payload.add(new typed.Uint8Buffer(1)..add(val));
  }
}
