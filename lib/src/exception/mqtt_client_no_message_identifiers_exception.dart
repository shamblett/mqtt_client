part of '../../mqtt_client.dart';

/// Exception thrown when no packet identifier is available for a new exchange.
class NoMessageIdentifiersException implements Exception {
  @override
  String toString() =>
      'mqtt-client::NoMessageIdentifiersException: '
      'No MQTT message identifiers available';
}
