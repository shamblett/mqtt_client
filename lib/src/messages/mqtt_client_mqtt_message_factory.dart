/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 15/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Factory for generating instances of MQTT Messages
class MqttMessageFactory {
  /// Gets an instance of an MqttMessage based on the message type requested.
  static MqttMessage getMessage(
      MqttHeader header, MqttByteBuffer messageStream) {
    MqttMessage message;
    switch (header.messageType) {
      case MqttMessageType.connect:
        message = MqttConnectMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.connectAck:
        message = MqttConnectAckMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.publish:
        message = MqttPublishMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.publishAck:
        message = MqttPublishAckMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.publishComplete:
        message =
            MqttPublishCompleteMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.publishReceived:
        message =
            MqttPublishReceivedMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.publishRelease:
        message =
            MqttPublishReleaseMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.subscribe:
        message = MqttSubscribeMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.subscribeAck:
        message = MqttSubscribeAckMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.unsubscribe:
        message = MqttUnsubscribeMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.unsubscribeAck:
        message =
            MqttUnsubscribeAckMessage.fromByteBuffer(header, messageStream);
        break;
      case MqttMessageType.pingRequest:
        message = MqttPingRequestMessage.fromHeader(header);
        break;
      case MqttMessageType.pingResponse:
        message = MqttPingResponseMessage.fromHeader(header);
        break;
      case MqttMessageType.disconnect:
        message = MqttDisconnectMessage.fromHeader(header);
        break;
      default:
        throw InvalidHeaderException(
            'The Message Type specified ($header.messageType) is not a valid '
            'MQTT Message type or currently not supported.');
    }
    return message;
  }
}
