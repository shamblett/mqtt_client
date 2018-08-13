/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Class that contains details related to an MQTT Unsubscribe messages payload
class MqttUnsubscribePayload extends MqttPayload {
  MqttVariableHeader variableHeader;
  MqttHeader header;

  /// The collection of subscriptions.
  List<String> subscriptions = List<String>();

  /// Initializes a new instance of the MqttUnsubscribePayload class.
  MqttUnsubscribePayload();

  /// Initializes a new instance of the MqttUnsubscribePayload class.
  MqttUnsubscribePayload.fromByteBuffer(MqttHeader header,
      MqttUnsubscribeVariableHeader variableHeader,
      MqttByteBuffer payloadStream) {
    this.header = header;
    this.variableHeader = variableHeader;
    readFrom(payloadStream);
  }

  /// Writes the payload to the supplied stream.
  void writeTo(MqttByteBuffer payloadStream) {
    for (String subscription in subscriptions) {
      payloadStream.writeMqttStringM(subscription);
    }
  }

  /// Creates a payload from the specified header stream.
  void readFrom(MqttByteBuffer payloadStream) {
    int payloadBytesRead = 0;
    final int payloadLength = header.messageSize - variableHeader.length;
    // Read all the topics and qos subscriptions from the message payload
    while (payloadBytesRead < payloadLength) {
      final String topic = payloadStream.readMqttStringM();
      payloadBytesRead += topic.length + 2; // +2 = Mqtt string length bytes
      addSubscription(topic);
    }
  }

  /// Gets the length of the payload in bytes when written to a stream.
  int getWriteLength() {
    int length = 0;
    final MqttEncoding enc = MqttEncoding();
    for (String subscription in subscriptions) {
      length += enc.getByteCount(subscription);
    }
    return length;
  }

  /// Adds a new subscription to the collection of subscriptions.
  void addSubscription(String topic) {
    subscriptions.add(topic);
  }

  /// Clears the subscriptions.
  void clearSubscriptions() {
    subscriptions.clear();
  }

  String toString() {
    final StringBuffer sb = StringBuffer();
    sb.writeln("Payload: Unsubscription [{${subscriptions.length}}]");
    for (String subscription in subscriptions) {
      sb.writeln("{{ Topic={$subscription}}");
    }
    return sb.toString();
  }
}
