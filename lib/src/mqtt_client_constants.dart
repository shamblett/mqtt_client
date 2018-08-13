/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

class Constants {
  /// The Maximum allowed message size as defined by the MQTT v3 Spec (256MB).
  static const int maxMessageSize = 268435455;

  /// The Maximum allowed client identifier length as specified by the 3.1
  /// specification is 23 characters, however we allow more than this, a warning is
  /// given in the log if 23 is exceeded.
  static const int maxClientIdentifierLength = 1024;
  static const int maxClientIdentifierLengthSpec = 23;

  /// The default Mqtt port to connect to.
  static const int defaultMqttPort = 1883;

  /// The recommended length for usernames and passwords.
  static const int recommendedMaxUsernamePasswordLength = 12;

  /// Default keep alive in seconds
  static int defaultKeepAlive = 60;

  /// Protocol variants
  static const int mqttV31ProtocolVersion = 3;
  static const String mqttV31ProtocolName = "MQIsdp";
  static const int mqttV311ProtocolVersion = 4;
  static const String mqttV311ProtocolName = "MQTT";
}
