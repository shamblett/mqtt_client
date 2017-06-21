/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Class that contains details related to an MQTT Subscribe messages payload
class MqttSubscribePayload extends MqttPayload {
  MqttVariableHeader variableHeader;
  MqttHeader header;

  /// The collection of subscriptions, Key is the topic, Value is the qos
  Map<String, MqttQos> subscriptions = new Map<String, MqttQos>();

  /// Initializes a new instance of the MqttSubscribePayload class.
  MqttSubscribePayload();

  /// Initializes a new instance of the <see cref="MqttSubscribePayload" /> class.
  MqttSubscribePayload.fromByteBuffer(MqttHeader header,
      MqttSubscribeVariableHeader variableHeader,
      MqttByteBuffer payloadStream) {
    this.header = header;
    this.variableHeader = variableHeader;
    readFrom(payloadStream);
  }

  /// Writes the payload to the supplied stream.
  void writeTo(MqttByteBuffer payloadStream) {
    subscriptions.forEach((String key, MqttQos value) {
      payloadStream.writeMqttStringM(key);
      payloadStream.writeByte(value.index);
    });
  }

  /// Creates a payload from the specified header stream.
  void readFrom(MqttByteBuffer payloadStream) {
    int payloadBytesRead = 0;
    final int payloadLength = header.messageSize - variableHeader.length;
    // Read all the topics and qos subscriptions from the message payload
    while (payloadBytesRead < payloadLength) {
      final String topic = payloadStream.readMqttStringM();
      final MqttQos qos = MqttQos.values[payloadStream.readByte()];
      payloadBytesRead +=
          topic.length + 3; // +3 = Mqtt string length bytes + qos byte
      addSubscription(topic, qos);
    }
  }

  /// Gets the length of the payload in bytes when written to a stream.
  int getWriteLength() {
    int length = 0;
    final MqttEncoding enc = new MqttEncoding();
    subscriptions.forEach((String key, MqttQos value) {
      length += enc.getByteCount(key);
      length += 1;
    });
    return length;
  }

  /// Adds a new subscription to the collection of subscriptions.
  void addSubscription(String topic, MqttQos qos) {
    subscriptions[topic] = qos;
  }

  /// Clears the subscriptions.
  void clearSubscriptions() {
    subscriptions.clear();
  }

  String toString() {
    final StringBuffer sb = new StringBuffer();
    sb.writeln("Payload: Subscription [{$subscriptions.length}]");
    subscriptions.forEach((String key, MqttQos value) {
      sb.writeln("{{ Topic={$key}, Qos={$value} }}");
    });
    return sb.toString();
  }
}
