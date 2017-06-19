/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Implementation of an MQTT Disconnect Message.
class MqttDisconnectMessage extends MqttMessage {
  /// Initializes a new instance of the <see cref="MqttPublishMessage" /> class.
  MqttDisconnectMessage() {
    this.header = new MqttHeader().asType(MqttMessageType.disconnect);
  }

  /// Initializes a new instance of the <see cref="MqttConnectMessage" /> class.
  MqttDisconnectMessage.fromHeader(MqttHeader header) {
    this.header = header;
  }

  String toString() {
    final StringBuffer sb = new StringBuffer();
    sb.write(super.toString());
    return sb.toString();
  }
}
