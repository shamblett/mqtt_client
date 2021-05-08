/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// An Mqtt message that is used to initiate a connection to a message broker.
class MqttConnectMessage extends MqttMessage {
  /// Initializes a new instance of the MqttConnectMessage class.
  /// Only called via the MqttMessage.create operation during processing of
  /// an Mqtt message stream.
  MqttConnectMessage() {
    header = MqttHeader().asType(MqttMessageType.connect);
    variableHeader = MqttConnectVariableHeader();
    payload = MqttConnectPayload(variableHeader);
  }

  ///  Initializes a new instance of the MqttConnectMessage class.
  MqttConnectMessage.fromByteBuffer(
      MqttHeader header, MqttByteBuffer messageStream) {
    this.header = header;
    readFrom(messageStream);
  }

  /// Sets the name of the protocol to use.
  MqttConnectMessage withProtocolName(String protocolName) {
    variableHeader!.protocolName = protocolName;
    return this;
  }

  /// Sets the protocol version. (Defaults to v3, the only protcol
  /// version supported)
  MqttConnectMessage withProtocolVersion(int protocolVersion) {
    variableHeader!.protocolVersion = protocolVersion;
    return this;
  }

  /// Sets the startClean flag so that the broker drops any messages
  /// that were previously destined for us.
  MqttConnectMessage startClean() {
    variableHeader!.connectFlags.cleanStart = true;
    return this;
  }

  /// Sets the keep alive period
  @Deprecated(
      'This will be removed, you must now set this through the client keepAlivePeriod')
  MqttConnectMessage keepAliveFor(int keepAliveSeconds) {
    variableHeader!.keepAlive = keepAliveSeconds;
    return this;
  }

  /// Sets the Will flag of the variable header
  MqttConnectMessage will() {
    variableHeader!.connectFlags.willFlag = true;
    return this;
  }

  /// Sets the WillQos of the connect flag.
  MqttConnectMessage withWillQos(MqttQos qos) {
    variableHeader!.connectFlags.willQos = qos;
    return this;
  }

  /// Sets the WillRetain flag of the Connection Flags
  MqttConnectMessage withWillRetain() {
    variableHeader!.connectFlags.willRetain = true;
    return this;
  }

  /// Sets the client identifier of the message.
  MqttConnectMessage withClientIdentifier(String clientIdentifier) {
    payload.clientIdentifier = clientIdentifier;
    return this;
  }

  /// Sets the will message.
  MqttConnectMessage withWillMessage(String willMessage) {
    will();
    payload.willMessage = willMessage;
    return this;
  }

  /// Sets the Will Topic
  MqttConnectMessage withWillTopic(String willTopic) {
    will();
    payload.willTopic = willTopic;
    return this;
  }

  /// Sets the authentication
  MqttConnectMessage authenticateAs(String? username, String? password) {
    if (username != null) {
      variableHeader!.connectFlags.usernameFlag = username.isNotEmpty;
      payload.username = username;
    }
    if (password != null) {
      variableHeader!.connectFlags.passwordFlag = password.isNotEmpty;
      payload.password = password;
    }
    return this;
  }

  /// The variable header contents. Contains extended metadata about the message
  MqttConnectVariableHeader? variableHeader;

  /// The payload of the Mqtt Message.
  late MqttConnectPayload payload;

  /// Writes the message to the supplied stream.
  @override
  void writeTo(MqttByteBuffer messageStream) {
    header!.writeTo(variableHeader!.getWriteLength() + payload.getWriteLength(),
        messageStream);
    variableHeader!.writeTo(messageStream);
    payload.writeTo(messageStream);
  }

  /// Reads a message from the supplied stream.
  @override
  void readFrom(MqttByteBuffer messageStream) {
    variableHeader = MqttConnectVariableHeader.fromByteBuffer(messageStream);
    payload = MqttConnectPayload.fromByteBuffer(variableHeader, messageStream);
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(super.toString());
    sb.writeln(variableHeader.toString());
    sb.writeln(payload.toString());
    return sb.toString();
  }
}
