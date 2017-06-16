/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Represents the Fixed Header of an MQTT message.
class MqttHeader {
  /// Initializes a new instance of the MqttHeader class.
  MqttHeader();

  /// Initializes a new instance of MqttHeader" based on data contained within the supplied stream.
  MqttHeader.fromByteBuffer(MqttByteBuffer headerStream) {
    readFrom(headerStream);
  }

  /// Backing storage for the payload size.
  int _messageSize = 0;

  /// Gets or sets the type of the MQTT message.
  MqttMessageType messageType;

  /// Gets or sets a value indicating whether this MQTT Message is duplicate of a previous message.
  /// True if duplicate; otherwise, false.
  bool duplicate = false;

  /// Gets or sets the Quality of Service indicator for the message.
  MqttQos qos = MqttQos.atMostOnce;

  /// Gets or sets a value indicating whether this MQTT message should be retained by the message broker for transmission to new subscribers.
  /// True if message should be retained by the message broker; otherwise, false.
  /// </value>
  bool retain = false;

  ///     Gets or sets the size of the variable header + payload section of the message.
  /// <value>The size of the variable header + payload.</value>
  /// <exception cref="Nmqtt.InvalidPayloadSizeException">The size of the variable header + payload exceeds the maximum allowed size.</exception>
  int get messageSize => _messageSize;

  set messageSize(int value) {
    if (value < 0 || value > Constants.maxMessageSize) {
      throw new InvalidPayloadSizeException(value, Constants.maxMessageSize);
    }
    _messageSize = value;
  }

  /// Writes the header to a supplied stream.
  void writeTo(int messageSize, MqttByteBuffer messageStream) {
    _messageSize = messageSize;
    final typed.Uint8Buffer headerBuff = headerBytes();
    messageStream.write(headerBuff);
  }

  /// Creates a new MqttHeader based on a list of bytes.
  void readFrom(MqttByteBuffer headerStream) {
    if (headerStream.length < 2) {
      throw new InvalidHeaderException(
          "The supplied header is invalid. Header must be at least 2 bytes long.");
    }
    final int firstHeaderByte = headerStream.readByte();
    // Pull out the first byte
    retain = ((firstHeaderByte & 1) == 1 ? true : false);
    qos = MqttQos.values[((firstHeaderByte & 6) >> 1)];
    duplicate = (((firstHeaderByte & 8) >> 3) == 1 ? true : false);
    messageType = MqttMessageType.values[((firstHeaderByte & 240) >> 4)];

    // Decode the remaining bytes as the remaining/payload size, input param is the 2nd to last byte of the header byte list
    try {
      _messageSize = readRemainingLength(headerStream);
    } catch (InvalidPayloadSizeException) {
      throw new InvalidHeaderException(
          "The header being processed contained an invalid size byte pattern." +
              "Message size must take a most 4 bytes, and the last byte must have bit 8 set to 0.");
    }
  }

  /// Gets the value of the Mqtt header as a byte array
  typed.Uint8Buffer headerBytes() {
    final typed.Uint8Buffer headerBytes = new typed.Uint8Buffer();

    // Build the bytes that make up the header. The first byte is a combination of message type, dup,
    // qos and retain, and the follow bytes (up to 4 of them) are the size of the payload + variable header.
    final int messageTypeLength = messageType.index << 4;
    final int duplicateLength = (duplicate ? 1 : 0) << 3;
    final int qosLength = qos.index << 1;
    final int retainLength = retain ? 1 : 0;
    final int firstByte = messageTypeLength + duplicateLength +
        qosLength + retainLength;
    headerBytes.add(firstByte);
    headerBytes.addAll(getRemainingLengthBytes());
    return headerBytes;
  }

  static int readRemainingLength(MqttByteBuffer headerStream) {
    final typed.Uint8Buffer lengthBytes = readLengthBytes(headerStream);
    return calculateLength(lengthBytes);
  }

  /// Reads the length bytes of an MqttHeader from the supplied stream.
  static typed.Uint8Buffer readLengthBytes(MqttByteBuffer headerStream) {
    final typed.Uint8Buffer lengthBytes = new typed.Uint8Buffer();
    // Read until we've got the entire size, or the 4 byte limit is reached
    int sizeByte;
    int byteCount = 0;
    do {
      sizeByte = headerStream.readByte();
      lengthBytes.add(sizeByte);
    } while (++byteCount <= 4 && (sizeByte & 0x80) == 0x80);
    return lengthBytes;
  }

  /// Calculates and return the bytes that represent the remaining length of the message.
  typed.Uint8Buffer getRemainingLengthBytes() {
    final typed.Uint8Buffer lengthBytes = new typed.Uint8Buffer();
    int payloadCalc = _messageSize;

    // Generate a byte array based on the message size, splitting it up into
    // 7 bit chunks, with the 8th bit being used to indicate "one more to come"
    do {
      int nextByteValue = payloadCalc % 128;
      payloadCalc = (payloadCalc ~/ 128);
      if (payloadCalc > 0) {
        nextByteValue = nextByteValue | 0x80;
      }
      lengthBytes.add(nextByteValue);
    } while (payloadCalc > 0);

    return lengthBytes;
  }

  /// Calculates the remaining length of an mqttmessage from the bytes that make up the length
  static int calculateLength(typed.Uint8Buffer lengthBytes) {
    var remainingLength = 0;
    var multiplier = 1;

    for (int currentByte in lengthBytes) {
      remainingLength += (currentByte & 0x7f) * multiplier;
      multiplier *= 0x80;
    }
    return remainingLength;
  }

  /// Sets the IsDuplicate flag of the header.
  MqttHeader isDuplicate() {
    this.duplicate = true;
    return this;
  }

  /// Sets the Qos of the message header.
  MqttHeader withQos(MqttQos qos) {
    this.qos = qos;
    return this;
  }

  /// Sets the type of the message identified in the header.
  MqttHeader asType(MqttMessageType messageType) {
    this.messageType = messageType;
    return this;
  }

  /// Defines that the message should be retained.
  MqttHeader shouldBeRetained() {
    this.retain = true;
    return this;
  }

  String toString() {
    return "Header: MessageType = $messageType, Duplicate = $duplicate, Retain = $retain, Qos = $qos, Size = $_messageSize";
  }
}
