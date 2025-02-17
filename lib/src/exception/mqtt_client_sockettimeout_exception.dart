/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of '../../mqtt_client.dart';

/// Exception thrown when the client fails to connect
class SocketTimeoutException implements Exception {
  /// Construct
  SocketTimeoutException(String message) {
    _message = 'mqtt-client::SocketTimeoutException: $message';
  }

  late String _message;

  @override
  String toString() => _message;
}
