/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Exception thrown when the connection state is incorrect.
class ConnectionException implements Exception {
  /// Construct
  ConnectionException(MqttConnectionState state) {
    _message =
        'mqtt-client::ConnectionException: The connection must be in the Connected state in order to perform this operation. '
        'Current state is ${state.toString().split('.')[1]}';
  }

  String _message;

  @override
  String toString() => _message;
}
