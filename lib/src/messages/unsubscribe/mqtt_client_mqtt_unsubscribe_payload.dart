/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

// ignore_for_file: avoid_types_on_closure_parameters
// ignore_for_file: cascade_invocations
// ignore_for_file: unnecessary_final
// ignore_for_file: omit_local_variable_types
// ignore_for_file: avoid_returning_this

/// Class that contains details related to an MQTT Unsubscribe messages payload
class MqttUnsubscribePayload extends MqttPayload {
  /// Initializes a new instance of the MqttUnsubscribePayload class.
  MqttUnsubscribePayload();

  /// Initializes a new instance of the MqttUnsubscribePayload class.
  MqttUnsubscribePayload.fromByteBuffer(
      this.header, this.variableHeader, MqttByteBuffer payloadStream) {
    readFrom(payloadStream);
  }

  /// Variable header
  MqttVariableHeader variableHeader;

  /// Message header
  MqttHeader header;

  /// The collection of subscriptions.
  List<String> subscriptions = <String>[];

  /// Writes the payload to the supplied stream.
  @override
  void writeTo(MqttByteBuffer payloadStream) {
    subscriptions.forEach(payloadStream.writeMqttStringM);
  }

  /// Creates a payload from the specified header stream.
  @override
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
  @override
  int getWriteLength() {
    int length = 0;
    final MqttEncoding enc = MqttEncoding();
    for (final String subscription in subscriptions) {
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

  @override
  String toString() {
    final StringBuffer sb = StringBuffer();
    sb.writeln('Payload: Unsubscription [{${subscriptions.length}}]');
    for (final String subscription in subscriptions) {
      sb.writeln('{{ Topic={$subscription}}');
    }
    return sb.toString();
  }
}
