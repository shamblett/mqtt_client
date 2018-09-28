/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 30/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Message identifier handling
class MessageIdentifierDispenser {
  static MessageIdentifierDispenser _singleton =
  new MessageIdentifierDispenser._internal();

  MessageIdentifierDispenser._internal();

  factory MessageIdentifierDispenser() {
    return _singleton;
  }

  /// Maximum message identifier
  static const int maxMessageIdentifier = 32768;

  /// Minimum message identifier
  static const int startMessageIdentifier = 1;

  /// Message identifier, zero is forbidden
  int _mid = 0;

  int get mid => _mid;

  /// Gets the next message identifier
  int getNextMessageIdentifier() {
    _mid++;
    if (_mid == maxMessageIdentifier) {
      _mid = startMessageIdentifier;
    }
    return mid;
  }

  /// Resets the mid
  void reset() {
    _mid = 0;
  }
}
