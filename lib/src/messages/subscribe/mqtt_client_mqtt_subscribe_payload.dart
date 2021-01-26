/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Class that contains details related to an MQTT Subscribe messages payload
class MqttSubscribePayload extends MqttPayload {
  /// Initializes a new instance of the MqttSubscribePayload class.
  MqttSubscribePayload();

  /// Initializes a new instance of the MqttSubscribePayload class.
  MqttSubscribePayload.fromByteBuffer(
      this.header, this.variableHeader, MqttByteBuffer payloadStream) {
    readFrom(payloadStream);
  }

  /// Variable header
  MqttVariableHeader? variableHeader;

  /// Message header
  MqttHeader? header;

  /// The collection of subscriptions, Key is the topic, Value is the qos
  Map<String?, MqttQos?> subscriptions = <String?, MqttQos?>{};

  /// Writes the payload to the supplied stream.
  @override
  void writeTo(MqttByteBuffer payloadStream) {
    subscriptions.forEach((String? key, MqttQos? value) {
      payloadStream.writeMqttStringM(key!);
      payloadStream.writeByte(value!.index);
    });
  }

  /// Creates a payload from the specified header stream.
  @override
  void readFrom(MqttByteBuffer payloadStream) {
    var payloadBytesRead = 0;
    final payloadLength = header!.messageSize - variableHeader!.length;
    // Read all the topics and qos subscriptions from the message payload
    while (payloadBytesRead < payloadLength) {
      final topic = payloadStream.readMqttStringM();
      final qos = MqttUtilities.getQosLevel(payloadStream.readByte());
      payloadBytesRead +=
          topic.length + 3; // +3 = Mqtt string length bytes + qos byte
      addSubscription(topic, qos);
    }
  }

  /// Gets the length of the payload in bytes when written to a stream.
  @override
  int getWriteLength() {
    var length = 0;
    final enc = MqttEncoding();
    subscriptions.forEach((String? key, MqttQos? value) {
      length += enc.getByteCount(key!);
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

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln('Payload: Subscription [{${subscriptions.length}}]');
    subscriptions.forEach((String? key, MqttQos? value) {
      sb.writeln('{{ Topic={$key}, Qos={$value} }}');
    });
    return sb.toString();
  }
}
