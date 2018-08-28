/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Represents the connect flags part of the MQTT Variable Header
class MqttConnectFlags {
  bool reserved1 = false;
  bool cleanStart = false;
  bool willFlag = false;
  MqttQos willQos = MqttQos.atMostOnce;
  bool willRetain = false;
  bool passwordFlag = false;
  bool usernameFlag = false;

  /// Initializes a new instance of the <see cref="MqttConnectFlags" /> class.
  MqttConnectFlags();

  /// Initializes a new instance of the <see cref="MqttConnectFlags" /> class configured as per the supplied stream.
  MqttConnectFlags.fromByteBuffer(MqttByteBuffer connectFlagsStream) {
    readFrom(connectFlagsStream);
  }

  int connectFlagByte() {
    return ((reserved1 ? 1 : 0) |
        (cleanStart ? 1 : 0) << 1 |
        (willFlag ? 1 : 0) << 2 |
        (willQos.index) << 3 |
        (willRetain ? 1 : 0) << 5 |
        (passwordFlag ? 1 : 0) << 6 |
        (usernameFlag ? 1 : 0) << 7);
  }

  /// Writes the connect flag byte to the supplied stream.
  void writeTo(MqttByteBuffer connectFlagsStream) {
    connectFlagsStream.writeByte(connectFlagByte());
  }

  /// Reads the connect flags from the underlying stream.
  void readFrom(MqttByteBuffer stream) {
    final int connectFlagsByte = stream.readByte();

    reserved1 = (connectFlagsByte & 1) == 1;
    cleanStart = (connectFlagsByte & 2) == 2;
    willFlag = (connectFlagsByte & 4) == 4;
    willQos = MqttQos.values[((connectFlagsByte >> 3) & 3)];
    willRetain = (connectFlagsByte & 32) == 32;
    passwordFlag = (connectFlagsByte & 64) == 64;
    usernameFlag = (connectFlagsByte & 128) == 128;
  }

  /// Gets the length of data written when WriteTo is called.
  static int getWriteLength() {
    return 1;
  }

  /// Returns a String that represents the current connect flag settings
  String toString() {
    return "Connect Flags: Reserved1=$reserved1, CleanStart=$cleanStart, WillFlag=$willFlag, WillQos=$willQos, " +
        "WillRetain=$willRetain, PasswordFlag=$passwordFlag, UserNameFlag=$usernameFlag";
  }
}
