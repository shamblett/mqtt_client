/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Represents the connect flags part of the MQTT Variable Header
class MqttConnectFlags {
  /// Initializes a new instance of the MqttConnectFlags class.
  MqttConnectFlags();

  /// Initializes a new instance of the MqttConnectFlags class configured
  /// as per the supplied stream.
  MqttConnectFlags.fromByteBuffer(MqttByteBuffer connectFlagsStream) {
    readFrom(connectFlagsStream);
  }

  /// Reserved1
  bool reserved1 = false;

  /// Clean start
  bool cleanStart = false;

  /// Will
  bool willFlag = false;

  /// Will Qos
  MqttQos willQos = MqttQos.atMostOnce;

  /// Will retain
  bool willRetain = false;

  /// Password present
  bool passwordFlag = false;

  /// Username present
  bool usernameFlag = false;

  /// Return the connect flag value
  int connectFlagByte() =>
      (reserved1 ? 1 : 0) |
      (cleanStart ? 1 : 0) << 1 |
      (willFlag ? 1 : 0) << 2 |
      (willQos.index) << 3 |
      (willRetain ? 1 : 0) << 5 |
      (passwordFlag ? 1 : 0) << 6 |
      (usernameFlag ? 1 : 0) << 7;

  /// Writes the connect flag byte to the supplied stream.
  void writeTo(MqttByteBuffer connectFlagsStream) {
    connectFlagsStream.writeByte(connectFlagByte());
  }

  /// Reads the connect flags from the underlying stream.
  void readFrom(MqttByteBuffer stream) {
    final connectFlagsByte = stream.readByte();

    reserved1 = (connectFlagsByte & 1) == 1;
    cleanStart = (connectFlagsByte & 2) == 2;
    willFlag = (connectFlagsByte & 4) == 4;
    willQos = MqttUtilities.getQosLevel((connectFlagsByte >> 3) & 3);
    willRetain = (connectFlagsByte & 32) == 32;
    passwordFlag = (connectFlagsByte & 64) == 64;
    usernameFlag = (connectFlagsByte & 128) == 128;
  }

  /// Gets the length of data written when WriteTo is called.
  static int getWriteLength() => 1;

  /// Returns a String that represents the current connect flag settings
  @override
  String toString() =>
      'Connect Flags: Reserved1=$reserved1, CleanStart=$cleanStart, '
      'WillFlag=$willFlag, WillQos=$willQos, WillRetain=$willRetain, '
      'PasswordFlag=$passwordFlag, UserNameFlag=$usernameFlag';
}
