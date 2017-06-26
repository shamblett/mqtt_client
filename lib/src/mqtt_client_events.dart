/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// The message data available event raised by the Connection class
class MessageDataAvailable {
  /// The message bytes associated with the event
  List<int> messageBytes;

  /// As an Mqtt byte buffer
  MqttByteBuffer stream;

  /// Constructor
  MessageDataAvailable(List<int> messageBytes) {
    this.messageBytes = messageBytes;
    final typed.Uint8Buffer tmp = new typed.Uint8Buffer();
    tmp.addAll(messageBytes);
    stream = new MqttByteBuffer(tmp);
  }
}