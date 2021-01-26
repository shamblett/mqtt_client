/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Exception thrown when processing a header that is invalid in some way.
class InvalidHeaderException implements Exception {
  /// Construct
  InvalidHeaderException(String text) {
    _message = 'mqtt-client::InvalidHeaderException: $text';
  }

  late String _message;

  @override
  String toString() => _message;
}
