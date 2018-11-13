/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Class that contains details related to an MQTT Connect messages payload.
class MqttConnectPayload extends MqttPayload {
  /// Initializes a new instance of the MqttConnectPayload class.
  MqttConnectPayload(this.variableHeader);

  /// Initializes a new instance of the MqttConnectPayload class.
  MqttConnectPayload.fromByteBuffer(
      this.variableHeader, MqttByteBuffer payloadStream) {
    readFrom(payloadStream);
  }

  String _clientIdentifier = '';

  String get clientIdentifier => _clientIdentifier;

  set clientIdentifier(String id) {
    if (id.length > Constants.maxClientIdentifierLength) {
      throw ClientIdentifierException(id);
    }
    if (id.length > Constants.maxClientIdentifierLengthSpec) {
      MqttLogger.log(
          'MqttConnectPayload::Client id exceeds spec value of ${Constants.maxClientIdentifierLengthSpec}');
    }
    _clientIdentifier = id;
  }

  MqttConnectVariableHeader variableHeader = MqttConnectVariableHeader();
  String _username;

  String get username => _username;

  set username(String name) => _username = name != null ? name.trim() : name;
  String _password;

  String get password => _password;

  set password(String pwd) => _password = pwd != null ? pwd.trim() : pwd;
  String willTopic;
  String willMessage;

  /// Creates a payload from the specified header stream.
  void readFrom(MqttByteBuffer payloadStream) {
    clientIdentifier = payloadStream.readMqttStringM();
    if (this.variableHeader.connectFlags.willFlag) {
      willTopic = payloadStream.readMqttStringM();
      willMessage = payloadStream.readMqttStringM();
    }
    if (variableHeader.connectFlags.usernameFlag) {
      username = payloadStream.readMqttStringM();
    }
    if (variableHeader.connectFlags.passwordFlag) {
      password = payloadStream.readMqttStringM();
    }
  }

  /// Writes the connect message payload to the supplied stream.
  void writeTo(MqttByteBuffer payloadStream) {
    payloadStream.writeMqttStringM(clientIdentifier);
    if (variableHeader.connectFlags.willFlag) {
      payloadStream.writeMqttStringM(willTopic);
      payloadStream.writeMqttStringM(willMessage);
    }
    if (variableHeader.connectFlags.usernameFlag) {
      payloadStream.writeMqttStringM(username);
    }
    if (variableHeader.connectFlags.passwordFlag) {
      payloadStream.writeMqttStringM(password);
    }
  }

  int getWriteLength() {
    int length = 0;
    final MqttEncoding enc = MqttEncoding();
    length += enc.getByteCount(clientIdentifier);
    if (this.variableHeader.connectFlags.willFlag) {
      length += enc.getByteCount(willTopic);
      length += enc.getByteCount(willMessage);
    }
    if (variableHeader.connectFlags.usernameFlag) {
      length += enc.getByteCount(username);
    }
    if (variableHeader.connectFlags.passwordFlag) {
      length += enc.getByteCount(password);
    }
    return length;
  }
}
