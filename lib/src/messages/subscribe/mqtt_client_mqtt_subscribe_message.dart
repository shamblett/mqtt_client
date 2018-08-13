/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Implementation of an MQTT Subscribe Message.
class MqttSubscribeMessage extends MqttMessage {
  /// Gets or sets the variable header contents. Contains extended metadata about the message
  MqttSubscribeVariableHeader variableHeader;

  /// Gets or sets the payload of the Mqtt Message.
  MqttSubscribePayload payload;

  String _lastTopic;

  /// Initializes a new instance of the MqttSubscribeMessage class.
  MqttSubscribeMessage() {
    this.header = MqttHeader().asType(MqttMessageType.subscribe);
    this.header.qos = MqttQos.atLeastOnce;
    this.variableHeader = MqttSubscribeVariableHeader();
    this.payload = MqttSubscribePayload();
  }

  /// Initializes a new instance of the MqttSubscribeMessage class.
  MqttSubscribeMessage.fromByteBuffer(MqttHeader header,
      MqttByteBuffer messageStream) {
    this.header = header;
    this.header.qos = MqttQos.atLeastOnce;
    readFrom(messageStream);
  }

  /// Writes the message to the supplied stream.
  void writeTo(MqttByteBuffer messageStream) {
    this.header.writeTo(
        this.variableHeader.getWriteLength() + this.payload.getWriteLength(),
        messageStream);
    this.variableHeader.writeTo(messageStream);
    this.payload.writeTo(messageStream);
  }

  /// Reads a message from the supplied stream.
  void readFrom(MqttByteBuffer messageStream) {
    this.variableHeader =
        MqttSubscribeVariableHeader.fromByteBuffer(messageStream);
    this.payload = MqttSubscribePayload.fromByteBuffer(
        header, variableHeader, messageStream);
  }

  /// Adds a new subscription topic with the AtMostOnce Qos Level. If you want to change the
  /// Qos level follow this call with a call to AtTopic(MqttQos)
  MqttSubscribeMessage toTopic(String topic) {
    _lastTopic = topic;
    this.payload.addSubscription(topic, MqttQos.atMostOnce);
    return this;
  }

  /// Sets the Qos level of the last topic added to the subscription list via a call to ToTopic(string)
  MqttSubscribeMessage atQos(MqttQos qos) {
    if (this.payload.subscriptions.containsKey(_lastTopic)) {
      this.payload.subscriptions[_lastTopic] = qos;
    }
    return this;
  }

  /// Sets the message identifier on the subscribe message.
  MqttSubscribeMessage withMessageIdentifier(int messageIdentifier) {
    this.variableHeader.messageIdentifier = messageIdentifier;
    return this;
  }

  /// Sets the message up to request acknowledgement from the broker for each topic subscription.
  MqttSubscribeMessage expectAcknowledgement() {
    this.header.withQos(MqttQos.atLeastOnce);
    return this;
  }

  /// Sets the duplicate flag for the message to indicate its a duplicate of a previous message type
  /// with the same message identifier.
  MqttSubscribeMessage isDuplicate() {
    this.header.isDuplicate();
    return this;
  }

  String toString() {
    final StringBuffer sb = StringBuffer();
    sb.write(super.toString());
    sb.writeln(variableHeader.toString());
    sb.writeln(payload.toString());
    return sb.toString();
  }
}
