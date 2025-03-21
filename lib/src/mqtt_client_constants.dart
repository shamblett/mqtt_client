/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of '../mqtt_client.dart';

/// Library wide constants
class MqttClientConstants {
  /// The Maximum allowed message size as defined by the MQTT v3 Spec (256MB).
  static const int maxMessageSize = 268435455;

  /// The Maximum allowed client identifier length as specified by the 3.1
  /// specification is 23 characters, however we allow more than
  /// this as this was relaxed in the 3.1.1 specification and
  /// most brokers now support lengths greater than 23 characters.
  static const int maxClientIdentifierLength = 65535;

  /// The default Mqtt port to connect to.
  static const int defaultMqttPort = 1883;

  /// The recommended length for usernames and passwords.
  static const int recommendedMaxUsernamePasswordLength = 12;

  /// Default keep alive in seconds.
  /// The default of 0 disables keep alive.
  static const int defaultKeepAlive = 0;

  /// Default maximum connection attempts
  static const int defaultMaxConnectionAttempts = 3;

  /// Default connection attempt timeout period, milliseconds,
  static const int defaultConnectionAttemptTimeoutPeriod = 5000;

  /// Protocol variants
  /// V3
  static const int mqttV31ProtocolVersion = 3;

  /// V3 name
  static const String mqttV31ProtocolName = 'MQIsdp';

  /// V4
  static const int mqttV311ProtocolVersion = 4;

  /// V4 name
  static const String mqttV311ProtocolName = 'MQTT';

  /// The default websocket subprotocol list
  static const List<String> protocolsMultipleDefault = <String>[
    'mqtt',
    'mqttv3.1',
    'mqttv3.11',
  ];

  /// The default websocket subprotocol list for brokers who expect
  /// this field to be a single entry
  static const List<String> protocolsSingleDefault = <String>['mqtt'];

  /// Seconds to milliseconds multiplier
  static const int millisecondsMultiplier = 1000;
}
