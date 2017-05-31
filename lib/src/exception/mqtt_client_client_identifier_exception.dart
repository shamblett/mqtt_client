/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

class ClientIdentifierException implements Exception {
  String _message;

  ClientIdentifierException(String clientIdentifier) {
    _message =
    "mqtt-client::ClientIdentifierException: Client id $clientIdentifier is too long at ${clientIdentifier
        .length}, "
        "Maximum ClientIdentifier length is ${Constants
        .maxClientIdentifierLength}";
  }

  String toString() => _message;
}
