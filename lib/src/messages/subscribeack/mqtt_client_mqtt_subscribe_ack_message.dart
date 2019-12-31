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

/// Implementation of an MQTT Subscribe Ack Message.
class MqttSubscribeAckMessage extends MqttMessage {
  /// Initializes a new instance of the MqttSubscribeAckMessage class.
  MqttSubscribeAckMessage() {
    header = MqttHeader().asType(MqttMessageType.subscribeAck);
    variableHeader = MqttSubscribeAckVariableHeader();
    payload = MqttSubscribeAckPayload();
  }

  /// Initializes a new instance of the MqttSubscribeAckMessage class.
  MqttSubscribeAckMessage.fromByteBuffer(
      MqttHeader header, MqttByteBuffer messageStream) {
    this.header = header;
    readFrom(messageStream);
  }

  /// Gets or sets the variable header contents. Contains extended
  /// metadata about the message.
  MqttSubscribeAckVariableHeader variableHeader;

  /// Gets or sets the payload of the Mqtt Message.
  MqttSubscribeAckPayload payload;

  /// Writes the message to the supplied stream.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    header.writeTo(variableHeader.getWriteLength() + payload.getWriteLength(),
        messageStream);
    variableHeader.writeTo(messageStream);
    payload.writeTo(messageStream);
  }

  /// Reads a message from the supplied stream.
  @override
  void readFrom(MqttByteBuffer messageStream) {
    variableHeader =
        MqttSubscribeAckVariableHeader.fromByteBuffer(messageStream);
    payload = MqttSubscribeAckPayload.fromByteBuffer(
        header, variableHeader, messageStream);
  }

  /// Sets the message identifier on the subscribe message.
  MqttSubscribeAckMessage withMessageIdentifier(int messageIdentifier) {
    variableHeader.messageIdentifier = messageIdentifier;
    return this;
  }

  ///  Adds a Qos grant to the message.
  MqttSubscribeAckMessage addQosGrant(MqttQos qosGranted) {
    payload.addGrant(qosGranted);
    return this;
  }

  @override
  String toString() {
    final StringBuffer sb = StringBuffer();
    sb.write(super.toString());
    sb.writeln(variableHeader.toString());
    sb.writeln(payload.toString());
    return sb.toString();
  }
}
