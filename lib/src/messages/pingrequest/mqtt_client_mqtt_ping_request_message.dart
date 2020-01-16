/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Implementation of an MQTT ping Request Message.
class MqttPingRequestMessage extends MqttMessage {
  /// Initializes a new instance of the MqttPingRequestMessage class.
  MqttPingRequestMessage() {
    header = MqttHeader().asType(MqttMessageType.pingRequest);
  }

  /// Initializes a new instance of the MqttPingRequestMessage class.
  MqttPingRequestMessage.fromHeader(MqttHeader header) {
    this.header = header;
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(super.toString());
    return sb.toString();
  }
}
