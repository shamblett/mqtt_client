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
    connectionHandler!.registerForMessage(
        MqttMessageType.publishAck, handlePublishAcknowledgement);
    connectionHandler!
        .registerForMessage(MqttMessageType.publish, handlePublish);
    connectionHandler!.registerForMessage(
        MqttMessageType.publishComplete, handlePublishComplete);
    connectionHandler!.registerForMessage(
        MqttMessageType.publishRelease, handlePublishRelease);
    connectionHandler!.registerForMessage(
        MqttMessageType.publishReceived, handlePublishReceived);
  }

  /// Handles dispensing of message ids for messages published to a topic.
  MessageIdentifierDispenser messageIdentifierDispenser =
      MessageIdentifierDispenser();

  /// Stores messages that have been pubished but not yet acknowledged.
  Map<int, MqttPublishMessage> publishedMessages = <int, MqttPublishMessage>{};

  /// Stores Qos 1 messages that have been received but not yet acknowledged as
  /// manual acknowledgement has been selected.
  Map<int, MqttPublishMessage> awaitingManualAcknowledge =
      <int, MqttPublishMessage>{};

  /// Stores messages that have been received from a broker with qos level 2 (Exactly Once).
  Map<int?, MqttPublishMessage> receivedMessages = <int?, MqttPublishMessage>{};

  /// Stores a cache of data converters used when publishing data to a broker.
  Map<Type, Object> dataConverters = <Type, Object>{};

  /// The current connection handler.
  IMqttConnectionHandler? connectionHandler;

  final StreamController<MqttPublishMessage> _published =
      StreamController<MqttPublishMessage>.broadcast();

  /// The stream on which all confirmed published messages are added to
  StreamController<MqttPublishMessage> get published => _published;

  /// Indicates that received QOS 1 messages(AtLeastOnce) are not to be automatically acknowledged by
  /// the client. The user must do this when the message has been taken off the update stream
  /// using the [acknowledgeQos1Message] method.
  bool manuallyAcknowledgeQos1 = false;

  /// Raised when a message has been received by the client and the relevant QOS handshake is complete.
  @override
  MessageReceived? publishEvent;

  /// The event bus
  final events.EventBus? _clientEventBus;

  /// Publish a message to the broker on the specified topic.
  /// The topic to send the message to
  /// The QOS to use when publishing the message.
  /// The message to send.
  /// The message identifier assigned to the message.
  @override
  int publish(
      PublicationTopic topic, MqttQos qualityOfService, typed.Uint8Buffer data,
      [bool retain = false]) {
    MqttLogger.log(
        'PublishingManager::publish - entered with topic ${topic.rawTopic}');
    final msgId = messageIdentifierDispenser.getNextMessageIdentifier();
    final msg = MqttPublishMessage()
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
    connectionHandler!.sendMessage(msg);
    return msgId;
  }

  /// Handles the receipt of publish acknowledgement messages.
  bool handlePublishAcknowledgement(MqttMessage? msg) {
    final ackMsg = msg as MqttPublishAckMessage;
    // If we're expecting an ack for the message, remove it from the list of pubs awaiting ack.
    final messageIdentifier = ackMsg.variableHeader.messageIdentifier;
    MqttLogger.log(
        'PublishingManager::handlePublishAcknowledgement for message id $messageIdentifier');
    if (publishedMessages.keys.contains(messageIdentifier)) {
      _notifyPublish(publishedMessages[messageIdentifier!]);
      publishedMessages.remove(messageIdentifier);
    }
    return true;
  }

  /// Manually acknowledge a received QOS 1 message.
  /// Has no effect if [manuallyAcknowledgeQos1] is not in force
  /// or the message is not awaiting a QOS 1 acknowledge.
  /// Returns true if an acknowledgement is sent to the broker.
  bool acknowledgeQos1Message(MqttPublishMessage message) {
    final messageIdentifier = message.variableHeader!.messageIdentifier;
    if (awaitingManualAcknowledge.keys.contains(messageIdentifier) &&
        manuallyAcknowledgeQos1) {
      final ackMsg =
          MqttPublishAckMessage().withMessageIdentifier(messageIdentifier);
      connectionHandler!.sendMessage(ackMsg);
      awaitingManualAcknowledge.remove(messageIdentifier);
      return true;
    }
    return false;
  }

  /// Handles the receipt of publish messages from a message broker.
  bool handlePublish(MqttMessage? msg) {
    final pubMsg = msg as MqttPublishMessage;
    var publishSuccess = true;
    try {
      final topic = PublicationTopic(pubMsg.variableHeader!.topicName);
      MqttLogger.log(
          'PublishingManager::handlePublish - publish received from broker with topic $topic');
      if (pubMsg.header!.qos == MqttQos.atMostOnce) {
        // QOS AtMostOnce 0 require no response.
        // Send the message for processing to whoever is waiting.
        _clientEventBus!.fire(MessageReceived(topic, msg));
        _notifyPublish(msg);
      } else if (pubMsg.header!.qos == MqttQos.atLeastOnce) {
        // QOS AtLeastOnce 1 requires an acknowledgement
        // Send the message for processing to whoever is waiting.
        _clientEventBus!.fire(MessageReceived(topic, msg));
        _notifyPublish(msg);
        // If configured the client will send the acknowledgement, else the user must.
        final messageIdentifier = pubMsg.variableHeader!.messageIdentifier;
        if (!manuallyAcknowledgeQos1) {
          final ackMsg =
              MqttPublishAckMessage().withMessageIdentifier(messageIdentifier);
          connectionHandler!.sendMessage(ackMsg);
        } else {
          // Add to the awaiting manual acknowledge list
          awaitingManualAcknowledge[messageIdentifier!] = pubMsg;
        }
      } else if (pubMsg.header!.qos == MqttQos.exactlyOnce) {
        // QOS ExactlyOnce means we can't give it away yet, we need to do a handshake
        // to make sure the broker knows we got it, and we know he knows we got it.
        // If we've already got it thats ok, it just means its being republished because
        // of a handshake breakdown, overwrite our existing one for the sake of it
        if (!receivedMessages
            .containsKey(pubMsg.variableHeader!.messageIdentifier)) {
          receivedMessages[pubMsg.variableHeader!.messageIdentifier] = pubMsg;
        }
        final pubRecv = MqttPublishReceivedMessage()
            .withMessageIdentifier(pubMsg.variableHeader!.messageIdentifier);
        connectionHandler!.sendMessage(pubRecv);
      }
    } on Exception {
      publishSuccess = false;
    }
    return publishSuccess;
  }

  /// Handles the publish release, for messages that are undergoing Qos ExactlyOnce processing.
  bool handlePublishRelease(MqttMessage? msg) {
    final pubRelMsg = msg as MqttPublishReleaseMessage;
    final messageIdentifier = pubRelMsg.variableHeader.messageIdentifier;
    MqttLogger.log(
        'PublishingManager::handlePublishRelease - for message identifier $messageIdentifier');
    var publishSuccess = true;
    try {
      final pubMsg = receivedMessages.remove(messageIdentifier);
      if (pubMsg != null) {
        // Send the message for processing to whoever is waiting.
        final topic = PublicationTopic(pubMsg.variableHeader!.topicName);
        _clientEventBus!.fire(MessageReceived(topic, pubMsg));
        final compMsg = MqttPublishCompleteMessage()
            .withMessageIdentifier(pubMsg.variableHeader!.messageIdentifier);
        connectionHandler!.sendMessage(compMsg);
      }
    } on Exception {
      publishSuccess = false;
    }
    return publishSuccess;
  }

  /// Handles a publish complete message received from a broker.
  /// Returns true if the message flow completed successfully, otherwise false.
  bool handlePublishComplete(MqttMessage? msg) {
    final compMsg = msg as MqttPublishCompleteMessage;
    final messageIdentifier = compMsg.variableHeader.messageIdentifier;
    MqttLogger.log(
        'PublishingManager::handlePublishComplete - for message identifier $messageIdentifier');
    final publishMessage = publishedMessages.remove(messageIdentifier);
    _notifyPublish(publishMessage);
    return true;
  }

  /// Handles publish received messages during processing of QOS level 2 (Exactly once) messages.
  /// Returns true or false, depending on the success of message processing.
  bool handlePublishReceived(MqttMessage? msg) {
    final recvMsg = msg as MqttPublishReceivedMessage;
    final messageIdentifier = recvMsg.variableHeader.messageIdentifier;
    MqttLogger.log(
        'PublishingManager::handlePublishReceived - for message identifier $messageIdentifier');
    // If we've got a matching message, respond with a "ok release it for processing"
    if (publishedMessages.containsKey(messageIdentifier)) {
      final relMsg = MqttPublishReleaseMessage()
          .withMessageIdentifier(recvMsg.variableHeader.messageIdentifier);
      connectionHandler!.sendMessage(relMsg);
    }
    return true;
  }

  /// On publish complete add the message to the published stream if needed
  void _notifyPublish(MqttPublishMessage? message) {
    if (_published.hasListener && message != null) {
      MqttLogger.log(
          'PublishingManager::_notifyPublish - adding message to published stream for topic ${message.variableHeader!.topicName}');
      _published.add(message);
    }
  }
}
