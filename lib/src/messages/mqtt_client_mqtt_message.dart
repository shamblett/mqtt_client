/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Represents an MQTT message that contains a fixed header, variable header and message body.
/// Messages roughly look as follows.
/// ----------------------------
/// | Header, 2-5 Bytes Length |
/// ----------------------------
/// | Variable Header(VH)      |
/// | n Bytes Length           |
/// ----------------------------
/// | Message Payload          |
/// | 256MB minus VH Size      |
/// ----------------------------

class MqttMessage {
  /// The header of the MQTT Message. Contains metadata about the message
  MqttHeader header;

  /// Initializes a new instance of the MqttMessage class.
  MqttMessage();

  /// Initializes a new instance of the MqttMessage class.
  MqttMessage.fromHeader(MqttHeader header) {
    header = header;
  }

  /// Creates a new instance of an MQTT Message based on a raw message stream.
  static MqttMessage createFrom(MqttByteBuffer messageStream) {
    try {
      MqttHeader header = MqttHeader();
      // Pass the input stream sequentially through the component deserialization(create) methods
      // to build a full MqttMessage.
      header = MqttHeader.fromByteBuffer(messageStream);
      final MqttMessage message =
          MqttMessageFactory.getMessage(header, messageStream);
      return message;
    } catch (InvalidHeaderException) {
      throw InvalidMessageException(
          "The data provided in the message stream was not a valid MQTT Message");
    }
  }

  /// Writes the message to the supplied stream.
  void writeTo(MqttByteBuffer messageStream) {
    header.writeTo(0, messageStream);
  }

  /// Reads a message from the supplied stream.
  void readFrom(MqttByteBuffer messageStream) {}

  String toString() {
    final StringBuffer sb = StringBuffer();
    sb.write("MQTTMessage of type ");
    sb.writeln(this.header.messageType.toString());
    sb.writeln(header.toString());
    return sb.toString();
  }
}
