/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Represents an MQTT message that contains a fixed header, variable
/// header and message body.
///
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
  /// Initializes a new instance of the MqttMessage class.
  MqttMessage();

  /// Initializes a new instance of the MqttMessage class.
  MqttMessage.fromHeader(MqttHeader header) {
    header = header;
  }

  /// The header of the MQTT Message. Contains metadata about the message
  MqttHeader? header;

  /// Creates a new instance of an MQTT Message based on a raw message stream.
  static MqttMessage createFrom(MqttByteBuffer messageStream) {
    try {
      var header = MqttHeader();
      // Pass the input stream sequentially through the component
      // deserialization(create) methods to build a full MqttMessage.
      header = MqttHeader.fromByteBuffer(messageStream);
      //expected position after reading payload
      final expectedPos = messageStream.position + header.messageSize;

      if (messageStream.availableBytes < header.messageSize) {
        messageStream.reset();
        throw InvalidMessageException(
            'Available bytes is less than the message size');
      }
      final message = MqttMessageFactory.getMessage(header, messageStream);

      if (messageStream.position < expectedPos) {
        messageStream.skipBytes = expectedPos - messageStream.position;
      }

      return message;
    } on Exception catch (e) {
      throw InvalidMessageException(
          'The data provided in the message stream was not a '
          'valid MQTT Message, '
          'exception is $e');
    }
  }

  /// Writes the message to the supplied stream.
  void writeTo(MqttByteBuffer messageStream) {
    header!.writeTo(0, messageStream);
  }

  /// Reads a message from the supplied stream.
  void readFrom(MqttByteBuffer messageStream) {}

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write('MQTTMessage of type ');
    sb.writeln(header!.messageType.toString());
    sb.writeln(header.toString());
    return sb.toString();
  }
}
