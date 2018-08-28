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
  /// Only called via the MqttMessage.create operation during processing of an Mqtt message stream.
  MqttConnectMessage() {
    this.header = MqttHeader().asType(MqttMessageType.connect);
    this.variableHeader = MqttConnectVariableHeader();
    this.payload = MqttConnectPayload(this.variableHeader);
  }

  ///  Initializes a new instance of the <see cref="MqttConnectMessage" /> class.
  MqttConnectMessage.fromByteBuffer(
      MqttHeader header, MqttByteBuffer messageStream) {
    this.header = header;
    readFrom(messageStream);
  }

  /// Sets the name of the protocol to use.
  MqttConnectMessage withProtocolName(String protocolName) {
    this.variableHeader.protocolName = protocolName;
    return this;
  }

  /// Sets the protocol version. (Defaults to v3, the only protcol version supported)
  MqttConnectMessage withProtocolVersion(int protocolVersion) {
    this.variableHeader.protocolVersion = protocolVersion;
    return this;
  }

  /// Sets the startClean flag so that the broker drops any messages that were previously destined for us.
  MqttConnectMessage startClean() {
    this.variableHeader.connectFlags.cleanStart = true;
    return this;
  }

  /// Sets the keep alive period
  MqttConnectMessage keepAliveFor(int keepAliveSeconds) {
    this.variableHeader.keepAlive = keepAliveSeconds;
    return this;
  }

  /// Sets the Will flag of the variable header
  MqttConnectMessage will() {
    this.variableHeader.connectFlags.willFlag = true;
    return this;
  }

  /// Sets the WillQos of the connect flag.
  MqttConnectMessage withWillQos(MqttQos qos) {
    this.variableHeader.connectFlags.willQos = qos;
    return this;
  }

  /// Sets the WillRetain flag of the Connection Flags
  MqttConnectMessage withWillRetain() {
    this.variableHeader.connectFlags.willRetain = true;
    return this;
  }

  /// Sets the client identifier of the message.
  MqttConnectMessage withClientIdentifier(String clientIdentifier) {
    this.payload.clientIdentifier = clientIdentifier;
    return this;
  }

  /// Sets the will message.
  MqttConnectMessage withWillMessage(String willMessage) {
    will();
    this.payload.willMessage = willMessage;
    return this;
  }

  /// Sets the Will Topic
  MqttConnectMessage withWillTopic(String willTopic) {
    will();
    this.payload.willTopic = willTopic;
    return this;
  }

  /// Sets the authentication
  MqttConnectMessage authenticateAs(String username, String password) {
    if (username != null) {
      this.variableHeader.connectFlags.usernameFlag = username.isNotEmpty;
      this.payload.username = username;
    }
    if (password != null) {
      this.variableHeader.connectFlags.passwordFlag = password.isNotEmpty;
      this.payload.password = password;
    }
    return this;
  }

  /// The variable header contents. Contains extended metadata about the message
  MqttConnectVariableHeader variableHeader;

  /// The payload of the Mqtt Message.
  MqttConnectPayload payload;

  /// Writes the message to the supplied stream.
  void writeTo(MqttByteBuffer messageStream) {
    this.header.writeTo(
        variableHeader.getWriteLength() + payload.getWriteLength(),
        messageStream);
    this.variableHeader.writeTo(messageStream);
    this.payload.writeTo(messageStream);
  }

  /// Reads a message from the supplied stream.
  void readFrom(MqttByteBuffer messageStream) {
    this.variableHeader =
        MqttConnectVariableHeader.fromByteBuffer(messageStream);
    this.payload =
        MqttConnectPayload.fromByteBuffer(this.variableHeader, messageStream);
  }

  String toString() {
    final StringBuffer sb = StringBuffer();
    sb.write(super.toString());
    sb.writeln(variableHeader.toString());
    sb.writeln(payload.toString());
    return sb.toString();
  }
}
