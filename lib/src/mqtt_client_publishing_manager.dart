/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 30/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// Handles the logic and workflow surrounding the message publishing and receipt process.
///
///         It's probably worth going into a bit of the detail around publishing and Quality of Service levels
///         as they are primarily the reason why message publishing has been split out into this class.
///
///         There are 3 different QOS levels. QOS0 AtMostOnce(0), means that the message, when sent from broker to client, or
///         client to broker, should be delivered at most one time, and it does not matter if the message is
///         "lost". QOS 1, AtLeastOnce(1), means that the message should be successfully received by the receiving
///         party at least one time, so requires some sort of acknowledgement so the sender can re-send if the
///         receiver does not acknowledge.
///
///         QOS 2 ExactlyOnce(2) is a bit more complicated as it provides the facility for guaranteed delivery of the message
///         exactly one time, no more, no less.
///
///         Each of these have different message flow between the sender and receiver.</para>
///         QOS 0 - AtMostOnce
///           Sender --> Publish --> Receiver
///         QOS 1 - AtLeastOnce
///           Sender --> Publish --> Receiver --> PublishAck --> Sender
///                                      |
///                                      v
///                               Message Processor
///         QOS 2 - ExactlyOnce
///         Sender --> Publish --> Receiver --> PublishReceived --> Sender --> PublishRelease --> Reciever --> PublishComplete --> Sender
///                                                                                                   | v
///                                                                                            Message Processor
class PublishingManager implements IPublishingManager {
  /// Initializes a new instance of the PublishingManager class.
  PublishingManager(this.connectionHandler, this._clientEventBus) {
    connectionHandler.registerForMessage(
        MqttMessageType.publishAck, handlePublishAcknowledgement);
    connectionHandler.registerForMessage(
        MqttMessageType.publish, handlePublish);
    connectionHandler.registerForMessage(
        MqttMessageType.publishComplete, handlePublishComplete);
    connectionHandler.registerForMessage(
        MqttMessageType.publishRelease, handlePublishRelease);
    connectionHandler.registerForMessage(
        MqttMessageType.publishReceived, handlePublishReceived);
  }

  /// Handles dispensing of message ids for messages published to a topic.
  MessageIdentifierDispenser messageIdentifierDispenser =
      MessageIdentifierDispenser();

  /// Stores messages that have been pubished but not yet acknowledged.
  Map<int, MqttPublishMessage> publishedMessages =
      Map<int, MqttPublishMessage>();

  /// Stores messages that have been received from a broker with qos level 2 (Exactly Once).
  Map<int, MqttPublishMessage> receivedMessages =
      Map<int, MqttPublishMessage>();

  /// Stores a cache of data converters used when publishing data to a broker.
  Map<Type, Object> dataConverters = Map<Type, Object>();

  /// The current connection handler.
  IMqttConnectionHandler connectionHandler;

  StreamController<MqttPublishMessage> _published =
      StreamController<MqttPublishMessage>.broadcast();

  /// The stream on which all confirmed published messages are added to
  StreamController<MqttPublishMessage> get published => _published;

  /// Raised when a message has been recieved by the client and the relevant QOS handshake is complete.
  @override
  MessageReceived publishEvent;

  /// The event bus
  events.EventBus _clientEventBus;

  /// Publish a message to the broker on the specified topic.
  /// The topic to send the message to
  /// The QOS to use when publishing the message.
  /// The message to send.
  /// The message identifier assigned to the message.
  @override
  int publish(
      PublicationTopic topic, MqttQos qualityOfService, typed.Uint8Buffer data,
      [bool retain = false]) {
    final int msgId = messageIdentifierDispenser.getNextMessageIdentifier();
    final MqttPublishMessage msg = MqttPublishMessage()
        .toTopic(topic.toString())
        .withMessageIdentifier(msgId)
        .withQos(qualityOfService)
        .publishData(data);
    // Retain
    msg.setRetain(state: retain);
    // QOS level 1 or 2 messages need to be saved so we can do the ack processes
    if (qualityOfService == MqttQos.atLeastOnce ||
        qualityOfService == MqttQos.exactlyOnce) {
      publishedMessages[msgId] = msg;
    }
    connectionHandler.sendMessage(msg);
    return msgId;
  }

  /// Handles the receipt of publish acknowledgement messages.
  /// This callback simply removes it from the list of published messages.
  bool handlePublishAcknowledgement(MqttMessage msg) {
    final MqttPublishAckMessage ackMsg = msg;
    // If we're expecting an ack for the message, remove it from the list of pubs awaiting ack.
    if (publishedMessages.keys
        .contains(ackMsg.variableHeader.messageIdentifier)) {
      publishedMessages.remove(ackMsg.variableHeader.messageIdentifier);
    }
    return true;
  }

  /// Handles the receipt of publish messages from a message broker.
  bool handlePublish(MqttMessage msg) {
    final MqttPublishMessage pubMsg = msg;
    bool publishSuccess = true;
    try {
      final PublicationTopic topic =
          PublicationTopic(pubMsg.variableHeader.topicName);
      if (pubMsg.header.qos == MqttQos.atMostOnce) {
        // QOS AtMostOnce 0 require no response.
        // Send the message for processing to whoever is waiting.
        _clientEventBus.fire(MessageReceived(topic, msg));
        _notifyPublish(msg);
      } else if (pubMsg.header.qos == MqttQos.atLeastOnce) {
        // QOS AtLeastOnce 1 requires an acknowledgement
        // Send the message for processing to whoever is waiting.
        _clientEventBus.fire(MessageReceived(topic, msg));
        _notifyPublish(msg);
        final MqttPublishAckMessage ackMsg = MqttPublishAckMessage()
            .withMessageIdentifier(pubMsg.variableHeader.messageIdentifier);
        connectionHandler.sendMessage(ackMsg);
      } else if (pubMsg.header.qos == MqttQos.exactlyOnce) {
        // QOS ExactlyOnce means we can't give it away yet, we need to do a handshake
        // to make sure the broker knows we got it, and we know he knows we got it.
        // If we've already got it thats ok, it just means its being republished because
        // of a handshake breakdown, overwrite our existing one for the sake of it
        if (!receivedMessages
            .containsKey(pubMsg.variableHeader.messageIdentifier)) {
          receivedMessages[pubMsg.variableHeader.messageIdentifier] = pubMsg;
        }
        final MqttPublishReceivedMessage pubRecv = MqttPublishReceivedMessage()
            .withMessageIdentifier(pubMsg.variableHeader.messageIdentifier);
        connectionHandler.sendMessage(pubRecv);
      }
    } on Exception {
      publishSuccess = false;
    }
    return publishSuccess;
  }

  /// Handles the publish complete, for messages that are undergoing Qos ExactlyOnce processing.
  bool handlePublishRelease(MqttMessage msg) {
    final MqttPublishReleaseMessage pubRelMsg = msg;
    bool publishSuccess = true;
    try {
      final MqttPublishMessage pubMsg =
          receivedMessages.remove(pubRelMsg.variableHeader.messageIdentifier);
      if (pubMsg != null) {
        // Send the message for processing to whoever is waiting.
        final PublicationTopic topic =
            PublicationTopic(pubMsg.variableHeader.topicName);
        _clientEventBus.fire(MessageReceived(topic, pubMsg));
        final MqttPublishCompleteMessage compMsg = MqttPublishCompleteMessage()
            .withMessageIdentifier(pubMsg.variableHeader.messageIdentifier);
        connectionHandler.sendMessage(compMsg);
      }
    } on Exception {
      publishSuccess = false;
    }
    return publishSuccess;
  }

  /// Handles a publish complete message received from a broker.
  /// Returns true if the message flow completed successfully, otherwise false.
  bool handlePublishComplete(MqttMessage msg) {
    final MqttPublishCompleteMessage compMsg = msg;
    final MqttPublishMessage publishMessage =
        publishedMessages.remove(compMsg.variableHeader.messageIdentifier);
    if (publishMessage != null) {
      _notifyPublish(publishMessage);
      return true;
    }
    return false;
  }

  /// Handles publish received messages during processing of QOS level 2 (Exactly once) messages.
  /// Returns true or false, depending on the success of message processing.
  bool handlePublishReceived(MqttMessage msg) {
    final MqttPublishReceivedMessage recvMsg = msg;
    // If we've got a matching message, respond with a "ok release it for processing"
    if (publishedMessages
        .containsKey(recvMsg.variableHeader.messageIdentifier)) {
      final MqttPublishReleaseMessage relMsg = MqttPublishReleaseMessage()
          .withMessageIdentifier(recvMsg.variableHeader.messageIdentifier);
      connectionHandler.sendMessage(relMsg);
    }
    return true;
  }

  /// On publish complete add the message to the published stream if needed
  void _notifyPublish(MqttPublishMessage message) {
    if (_published.hasListener) {
      _published.add(message);
    }
  }
}
