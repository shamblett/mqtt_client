/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Exception thrown when the connection state is incorrect.
class ConnectionException implements Exception {
  String _message;

  /// Length of 'ConnectionException.'
  static const int _classLength = 16;

  ConnectionException(ConnectionState state) {
    _message =
    "mqtt-client::ConnectionException: The connection must be in the Connected state in order to perform this operation. "
        "Current state is ${state.toString().substring(_classLength)}";
  }

  @override
  String toString() => _message;
}
