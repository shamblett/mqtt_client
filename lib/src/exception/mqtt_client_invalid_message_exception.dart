/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of '../../mqtt_client.dart';

/// Exception thrown when processing a Message that is invalid in some way.
class InvalidMessageException implements Exception {
  late String _message;

  /// Construct
  InvalidMessageException(String text) {
    _message = 'mqtt-client::InvalidMessageException: $text';
  }

  @override
  String toString() => _message;
}
