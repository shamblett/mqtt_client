/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Enumeration of allowable connection request return codes from a broker.
enum MqttConnectReturnCode {
  /// Connection accepted
  connectionAccepted,

  /// Invalid protocol version
  unacceptedProtocolVersion,

  /// Invalid client identifier
  identifierRejected,

  /// Broker unavailable
  brokerUnavailable,

  /// Invalid username or password
  badUsernameOrPassword,

  /// Not authorised
  notAuthorized,

  /// Default
  noneSpecified
}
