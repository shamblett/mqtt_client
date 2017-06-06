/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Represents the base class for the Variable Header portion of some MQTT Messages.
class MqttVariableHeader {
  /// The length, in bytes, consumed by the variable header.
  int length;

  String protocolName;
  int protocolVersion;
  MqttConnectFlags connectFlags;

  /// Defines the maximum allowable lag, in seconds, between expected messages.
  /// The spec indicates that clients won't be disconnected until KeepAlive + 1/2 KeepAlive time period
  /// elapses.
  int keepAlive;

  MqttConnectReturnCode returnCode;
  String topicName;
  int messageIdentifier;

  /// Initializes a new instance of the <see cref="MqttVariableHeader" /> class.
  MqttVariableHeader() {
    this.protocolName = "MQIsdp";
    this.protocolVersion = 3;
    this.connectFlags = new MqttConnectFlags();
  }
}
