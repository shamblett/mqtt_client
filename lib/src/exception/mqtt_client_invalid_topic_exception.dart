/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of '../../mqtt_client.dart';

/// Exception thrown when the topic of a message is invalid
class InvalidTopicException implements Exception {
  late String _message;

  /// Construct
  InvalidTopicException(String message, String topic) {
    _message = 'mqtt-client::InvalidTopicException: Topic $topic is $message';
  }

  @override
  String toString() => _message;
}
