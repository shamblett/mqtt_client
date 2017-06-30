/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 30/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Message identifier handling
class MessageIdentifierDispenser {
  Map<String, int> _idStorage = new Map<String, int>();

  /// Gets the next message identifier for the specified key.
  int getNextMessageIdentifier(String key) {
    // Only a single id can be dispensed at a time, regardless of the key.
    // Will revise to per-key locking if it proves bottleneck
    int retVal = 0;
    if (!_idStorage.containsKey(key)) {
      _idStorage[key] =
      1; // add a new key, start at 1, 0 is reserved for by MQTT spec for invalid msg.
      retVal = 1;
    } else {
      int nextId = ++_idStorage[key];
      if (nextId == 32768) {
        // overflow, wrap back to 1.
        nextId = _idStorage[key] = 1;
      }
      retVal = nextId;
    }
    return retVal;
  }
}
