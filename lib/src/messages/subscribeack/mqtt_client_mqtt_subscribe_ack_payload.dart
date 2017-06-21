/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Class that contains details related to an MQTT Subscribe Ack messages payload
class MqttSubscribeAckPayload extends MqttPayload {
  MqttVariableHeader variableHeader;
  MqttHeader header;

  /// The collection of Qos grants, Key is the topic, Value is the qos
  List<MqttQos> qosGrants = new List<MqttQos>();

  /// Initializes a new instance of the MqttSubscribeAckPayload class.
  MqttSubscribeAckPayload();

  /// Initializes a new instance of the MqttSubscribeAckPayload class.
  MqttSubscribeAckPayload.fromByteBuffer(MqttHeader header,
      MqttSubscribeAckVariableHeader variableHeader,
      MqttByteBuffer payloadStream) {
    this.header = header;
    this.variableHeader = variableHeader;
    readFrom(payloadStream);
  }

  /// Writes the payload to the supplied stream.
  void writeTo(MqttByteBuffer payloadStream) {
    for (MqttQos value in qosGrants) {
      payloadStream.writeByte(value.index);
    }
  }

  /// Creates a payload from the specified header stream.
  void readFrom(MqttByteBuffer payloadStream) {
    int payloadBytesRead = 0;
    final int payloadLength = header.messageSize - variableHeader.length;
    // Read the qos grants from the message payload
    while (payloadBytesRead < payloadLength) {
      final MqttQos granted = MqttQos.values[payloadStream.readByte()];
      payloadBytesRead++;
      addGrant(granted);
    }
  }

  /// Gets the length of the payload in bytes when written to a stream.
  int getWriteLength() {
    return qosGrants.length;
  }

  /// Adds a new QosGrant to the collection of QosGrants
  void addGrant(MqttQos grantedQos) {
    qosGrants.add(grantedQos);
  }

  /// Clears the grants.
  void clearGrants() {
    qosGrants.clear();
  }

  String toString() {
    final StringBuffer sb = new StringBuffer();
    sb.writeln("Payload: Qos grants [{${qosGrants.length}}]");
    for (MqttQos value in qosGrants) {
      sb.writeln("{{ Grant={$value} }}");
    }
    return sb.toString();
  }
}
