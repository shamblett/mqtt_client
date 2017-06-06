/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Enumeration of allowable connection request return codes.
enum MqttConnectReturnCode {
  connectionAccepted,
  unacceptedProtocolVersion,
  identifierRejected,
  brokerUnavailable,
  badUsernameOrPassword,
  notAuthorized
}
