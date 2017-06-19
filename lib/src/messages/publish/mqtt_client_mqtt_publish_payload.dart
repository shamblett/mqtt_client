/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 19/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Class that contains details related to an MQTT Connect messages payload
class MqttPublishPayload extends MqttPayload {
  MqttHeader header;
  MqttPublishVariableHeader variableHeader;

  /// The message that forms the payload of the publish message.
  typed.Uint8Buffer message;

  /// Initializes a new instance of the MqttPublishPayload class.
  MqttPublishPayload() {
    this.message = new typed.Uint8Buffer();
  }

  /// Initializes a new instance of the MqttPublishPayload class.
  MqttPublishPayload.fromByteBuffer(MqttHeader header,
      MqttPublishVariableHeader variableHeader, MqttByteBuffer payloadStream) {
    this.header = header;
    this.variableHeader = variableHeader;
    readFrom(payloadStream);
  }

  /// Creates a payload from the specified header stream.
  void readFrom(MqttByteBuffer payloadStream) {
    // The payload of the publish message is not a string, just a binary chunk of bytes.
    // The length of the bytes is the length specified in the header, minus any bytes
    // spent in the variable header.
    final int messageBytes = header.messageSize - variableHeader.length;
    message = new typed.Uint8Buffer(messageBytes);
  }

  /// Writes the payload to the supplied stream.
  void writeTo(MqttByteBuffer payloadStream) {
    payloadStream.write(message);
  }

  /// Gets the length of the payload in bytes when written to a stream.
  int getWriteLength() {
    return message.length;
  }

  /// Returns a string representation of the payload.
  String toString() {
    return "Payload: {$message.length} bytes={$bytesToString(message}";
  }

  /// Converts an array of bytes to a byte string.
  static String bytesToString(typed.Uint8Buffer message) {
    final StringBuffer sb = new StringBuffer();
    for (var b in message) {
      sb.write('<');
      sb.write(b);
      sb.write('>');
    }
    return sb.toString();
  }
}
