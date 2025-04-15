/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/06/2017
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt_client.dart';

/// Class that contains details related to an MQTT Connect messages payload.
class MqttConnectPayload extends MqttPayload {
  /// Variable header
  MqttConnectVariableHeader? variableHeader = MqttConnectVariableHeader();

  /// Will topic
  String? willTopic;

  /// Will message
  String? willMessage;

  String? _username;

  String _clientIdentifier = '';

  String? _password;

  /// Client identifier
  String get clientIdentifier => _clientIdentifier;

  /// User name
  String? get username => _username;

  /// Password
  String? get password => _password;

  set clientIdentifier(String id) {
    if (id.length > MqttClientConstants.maxClientIdentifierLength) {
      throw ClientIdentifierException(id);
    }
    _clientIdentifier = id;
  }

  set username(String? name) => _username = name != null ? name.trim() : name;

  set password(String? pwd) => _password = pwd != null ? pwd.trim() : pwd;

  /// Initializes a new instance of the MqttConnectPayload class.
  MqttConnectPayload(this.variableHeader);

  /// Initializes a new instance of the MqttConnectPayload class.
  MqttConnectPayload.fromByteBuffer(
    this.variableHeader,
    MqttByteBuffer payloadStream,
  ) {
    readFrom(payloadStream);
  }

  /// Creates a payload from the specified header stream.
  @override
  void readFrom(MqttByteBuffer payloadStream) {
    clientIdentifier = payloadStream.readMqttStringM();
    if (variableHeader!.connectFlags.willFlag) {
      willTopic = payloadStream.readMqttStringM();
      willMessage = payloadStream.readMqttStringM();
    }
    if (variableHeader!.connectFlags.usernameFlag) {
      username = payloadStream.readMqttStringM();
    }
    if (variableHeader!.connectFlags.passwordFlag) {
      password = payloadStream.readMqttStringM();
    }
  }

  /// Writes the connect message payload to the supplied stream.
  @override
  void writeTo(MqttByteBuffer payloadStream) {
    payloadStream.writeMqttStringM(clientIdentifier);
    if (variableHeader!.connectFlags.willFlag) {
      payloadStream.writeMqttStringM(willTopic!);
      payloadStream.writeMqttStringM(willMessage!);
    }
    if (variableHeader!.connectFlags.usernameFlag) {
      payloadStream.writeMqttStringM(username!);
    }
    if (variableHeader!.connectFlags.passwordFlag) {
      payloadStream.writeMqttStringM(password!);
    }
  }

  @override
  int getWriteLength() {
    var length = 0;
    final enc = MqttEncoding();
    length += enc.getByteCount(clientIdentifier);
    if (variableHeader!.connectFlags.willFlag) {
      length += enc.getByteCount(willTopic!);
      length += enc.getByteCount(willMessage!);
    }
    if (variableHeader!.connectFlags.usernameFlag) {
      length += enc.getByteCount(username!);
    }
    if (variableHeader!.connectFlags.passwordFlag) {
      length += enc.getByteCount(password!);
    }
    return length;
  }

  @override
  String toString() =>
      'MqttConnectPayload - client identifier is : $clientIdentifier';
}
