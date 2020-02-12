/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 30/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Message identifier handling
class MessageIdentifierDispenser {
  /// Factory constructor
  factory MessageIdentifierDispenser() => _singleton;

  MessageIdentifierDispenser._internal();

  static final MessageIdentifierDispenser _singleton =
      MessageIdentifierDispenser._internal();

  /// Maximum message identifier
  static const int maxMessageIdentifier = 32768;

  /// Initial value
  static const int initialValue = 0;

  /// Minimum message identifier
  static const int startMessageIdentifier = 1;

  /// Message identifier, zero is forbidden
  int _mid = initialValue;

  /// Mid
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
    _mid = initialValue;
  }
}
