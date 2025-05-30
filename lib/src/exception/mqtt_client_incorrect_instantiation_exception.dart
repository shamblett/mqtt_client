/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 17/03/2020
 * Copyright :  S.Hamblett
 */

part of '../../mqtt_client.dart';

/// Exception thrown when a browser or server client is instantiated incorrectly.
class IncorrectInstantiationException implements Exception {
  late String _message;

  /// Construct
  IncorrectInstantiationException() {
    _message =
        'mqtt-client::ClientIncorrectInstantiationException: Incorrect instantiation, do not'
        'instantiate MqttClient directly, use MqttServerClient or MqttBrowserClient';
  }

  @override
  String toString() => _message;
}
