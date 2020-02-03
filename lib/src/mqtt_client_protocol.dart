/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Protocol selection helper class, protocol defaults V3.1
class Protocol {
  /// Version
  static int version = MqttClientConstants.mqttV31ProtocolVersion;

  /// Name
  static String name = MqttClientConstants.mqttV31ProtocolName;
}
