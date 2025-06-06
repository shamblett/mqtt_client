/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt_client.dart';

/// Class that contains details related to an MQTT Connect messages payload
class MqttPublishPayload extends MqttPayload {
  /// Message header
  MqttHeader? header;

  /// Variable header
  MqttPublishVariableHeader? variableHeader;

  /// The message that forms the payload of the publish message.
  late typed.Uint8Buffer message;

  /// Initializes a new instance of the MqttPublishPayload class.
  MqttPublishPayload() {
    message = typed.Uint8Buffer();
  }

  /// Initializes a new instance of the MqttPublishPayload class.
  MqttPublishPayload.fromByteBuffer(
    this.header,
    this.variableHeader,
    MqttByteBuffer payloadStream,
  ) {
    readFrom(payloadStream);
  }

  /// Creates a payload from the specified header stream.
  @override
  void readFrom(MqttByteBuffer payloadStream) {
    // The payload of the publish message is not a string, just
    // a binary chunk of bytes.
    // The length of the bytes is the length specified in the header,
    // minus any bytes spent in the variable header.
    final messageBytes = header!.messageSize - variableHeader!.length;
    message = payloadStream.readPayload(messageBytes);
  }

  /// Writes the payload to the supplied stream.
  @override
  void writeTo(MqttByteBuffer payloadStream) {
    payloadStream.write(message);
  }

  /// Gets the length of the payload in bytes when written to a stream.
  @override
  int getWriteLength() => message.length;

  @override
  String toString() =>
      'Payload: {${message.length} bytes={${bytesToString(message)}';

  /// Converts an array of bytes to a byte string.
  static String bytesToString(typed.Uint8Buffer message) {
    final sb = StringBuffer();
    for (final b in message) {
      sb.write('<');
      sb.write(b);
      sb.write('>');
    }
    return sb.toString();
  }

  /// Converts an array of bytes to a character string.
  static String bytesToStringAsString(typed.Uint8Buffer message) {
    return utf8.decode(message.toList());
  }
}
