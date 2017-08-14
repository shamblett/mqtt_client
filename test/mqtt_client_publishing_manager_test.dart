/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/06/2017
 * Copyright :  S.Hamblett
 */
import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'mqtt_client_test_connection_handler.dart';
import 'package:typed_data/typed_data.dart' as typed;

// Mock classes
class MockCH extends Mock implements MqttConnectionHandler {}

class MockCON extends Mock implements MqttTcpConnection {}

final TestConnectionHandlerNoSend testCHNS = new TestConnectionHandlerNoSend();
final TestConnectionHandlerSend testCHS = new TestConnectionHandlerSend();

void main() {
  group("Message Identifier", () {
    test("Numbering starts at 1", () {
      final MessageIdentifierDispenser dispenser =
      new MessageIdentifierDispenser();
      expect(
          dispenser
              .getNextMessageIdentifier("0374a85e-6aeb-4c5a-b7df-afece971c501"),
          1);
    });
    test("Numbering increments by 1", () {
      final MessageIdentifierDispenser dispenser =
      new MessageIdentifierDispenser();
      final int first =
      dispenser.getNextMessageIdentifier("Topic::Sample/My/Topic");
      final int second =
      dispenser.getNextMessageIdentifier("Topic::Sample/My/Topic");
      expect(second, first + 1);
    });
    test("Numbering overflows back to 1", () {
      final MessageIdentifierDispenser dispenser =
      new MessageIdentifierDispenser();
      for (int i = 0;
      i < MessageIdentifierDispenser.maxMessageIdentifier - 1;
      i = dispenser
          .getNextMessageIdentifier("Topic::Sample/My/Topic/Overflow")) {}
      // One more call should overflow us and reset us back to 1.
      expect(
          dispenser.getNextMessageIdentifier("Topic::Sample/My/Topic/Overflow"),
          1);
    });
  });

  group("Message registration", () {
    // Group wide
    final MockCON con = new MockCON();
    var message;
    when(con.send(message)).thenReturn(() => print(message?.toString()));
    final MockCH ch = new MockCH();
    testCHNS.connection = con;
    ch.connection = con;
    MessageCallbackFunction cbFunc;

    test("Register for publish messages", () {
      testCHNS.registerForMessage(MqttMessageType.publish, cbFunc);
      expect(
          testCHNS.messageProcessorRegistry
              .containsKey(MqttMessageType.publish),
          isTrue);
      expect(
          testCHNS.messageProcessorRegistry[MqttMessageType.publish], cbFunc);
    });
    test("Register for publish ack messages", () {
      testCHNS.registerForMessage(MqttMessageType.publishAck, cbFunc);
      expect(
          testCHNS.messageProcessorRegistry
              .containsKey(MqttMessageType.publishAck),
          isTrue);
      expect(testCHNS.messageProcessorRegistry[MqttMessageType.publishAck],
          cbFunc);
    });
    test("Register for publish complete messages", () {
      testCHNS.registerForMessage(MqttMessageType.publishComplete, cbFunc);
      expect(
          testCHNS.messageProcessorRegistry
              .containsKey(MqttMessageType.publishComplete),
          isTrue);
      expect(testCHNS.messageProcessorRegistry[MqttMessageType.publishComplete],
          cbFunc);
    });
    test("Register for publish received messages", () {
      testCHNS.registerForMessage(MqttMessageType.publishReceived, cbFunc);
      expect(
          testCHNS.messageProcessorRegistry
              .containsKey(MqttMessageType.publishReceived),
          isTrue);
      expect(testCHNS.messageProcessorRegistry[MqttMessageType.publishReceived],
          cbFunc);
    });
    test("Register for publish release messages", () {
      testCHNS.registerForMessage(MqttMessageType.publishRelease, cbFunc);
      expect(
          testCHNS.messageProcessorRegistry
              .containsKey(MqttMessageType.publishRelease),
          isTrue);
      expect(testCHNS.messageProcessorRegistry[MqttMessageType.publishRelease],
          cbFunc);
    });
  });

  group("Publishing", () {
    test("Publish at least once", () {
      testCHS.sentMessages.clear();
      final PublishingManager pm = new PublishingManager(testCHS);
      final typed.Uint8Buffer buff = new typed.Uint8Buffer(4);
      buff[0] = 't'.codeUnitAt(0);
      buff[1] = 'e'.codeUnitAt(0);
      buff[2] = 's'.codeUnitAt(0);
      buff[3] = 't'.codeUnitAt(0);
      final int msgId = pm.publish(
          new PublicationTopic("A/rawTopic"), MqttQos.atMostOnce, buff);
      expect(msgId, 1);
      expect(pm.publishedMessages.containsKey(1), isFalse);
      final MqttPublishMessage pubMess =
      testCHS.sentMessages[0] as MqttPublishMessage;
      expect(pubMess.header.messageType, MqttMessageType.publish);
      expect(pubMess.variableHeader.messageIdentifier, 1);
      expect(pubMess.header.qos, MqttQos.atMostOnce);
      expect(pubMess.variableHeader.topicName, "A/rawTopic");
      expect(pubMess.payload.toString(),
          "Payload: {4 bytes={<116><101><115><116>");
    });

    test("Publish at least once", () {
      testCHS.sentMessages.clear();
      final PublishingManager pm = new PublishingManager(testCHS);
      final typed.Uint8Buffer buff = new typed.Uint8Buffer(4);
      buff[0] = 't'.codeUnitAt(0);
      buff[1] = 'e'.codeUnitAt(0);
      buff[2] = 's'.codeUnitAt(0);
      buff[3] = 't'.codeUnitAt(0);
      final int msgId = pm.publish(
          new PublicationTopic("A/rawTopic"), MqttQos.atLeastOnce, buff);
      expect(msgId, 1);
      expect(pm.publishedMessages.containsKey(1), isTrue);
      final MqttPublishMessage pubMess = pm.publishedMessages[1];
      expect(pubMess.header.messageType, MqttMessageType.publish);
      expect(pubMess.variableHeader.messageIdentifier, 1);
      expect(pubMess.header.qos, MqttQos.atLeastOnce);
      expect(pubMess.variableHeader.topicName, "A/rawTopic");
      expect(pubMess.payload.toString(),
          "Payload: {4 bytes={<116><101><115><116>");
    });
    test("Publish at exactly once", () {
      testCHS.sentMessages.clear();
      final PublishingManager pm = new PublishingManager(testCHS);
      final typed.Uint8Buffer buff = new typed.Uint8Buffer(4);
      buff[0] = 't'.codeUnitAt(0);
      buff[1] = 'e'.codeUnitAt(0);
      buff[2] = 's'.codeUnitAt(0);
      buff[3] = 't'.codeUnitAt(0);
      final int msgId = pm.publish(
          new PublicationTopic("A/rawTopic"), MqttQos.exactlyOnce, buff);
      expect(msgId, 1);
      expect(pm.publishedMessages.containsKey(1), isTrue);
      final MqttPublishMessage pubMess = pm.publishedMessages[1];
      expect(pubMess.header.messageType, MqttMessageType.publish);
      expect(pubMess.variableHeader.messageIdentifier, 1);
      expect(pubMess.header.qos, MqttQos.exactlyOnce);
      expect(pubMess.variableHeader.topicName, "A/rawTopic");
      expect(pubMess.payload.toString(),
          "Payload: {4 bytes={<116><101><115><116>");
    });
    test("Publish consecutive topics", () {
      testCHS.sentMessages.clear();
      final PublishingManager pm = new PublishingManager(testCHS);
      final typed.Uint8Buffer buff = new typed.Uint8Buffer(4);
      buff[0] = 't'.codeUnitAt(0);
      buff[1] = 'e'.codeUnitAt(0);
      buff[2] = 's'.codeUnitAt(0);
      buff[3] = 't'.codeUnitAt(0);
      final int msgId1 = pm.publish(
          new PublicationTopic("A/rawTopic"), MqttQos.exactlyOnce, buff);
      final int msgId2 = pm.publish(
          new PublicationTopic("A/rawTopic"), MqttQos.exactlyOnce, buff);
      expect(msgId2, msgId1 + 1);
    });
    test("Publish at least once and ack", () {
      testCHS.sentMessages.clear();
      final PublishingManager pm = new PublishingManager(testCHS);
      final typed.Uint8Buffer buff = new typed.Uint8Buffer(4);
      buff[0] = 't'.codeUnitAt(0);
      buff[1] = 'e'.codeUnitAt(0);
      buff[2] = 's'.codeUnitAt(0);
      buff[3] = 't'.codeUnitAt(0);
      final int msgId = pm.publish(
          new PublicationTopic("A/rawTopic"), MqttQos.atLeastOnce, buff);
      expect(msgId, 1);
      pm.handlePublishAcknowledgement(
          new MqttPublishAckMessage().withMessageIdentifier(msgId));
      expect(pm.publishedMessages.containsKey(1), isFalse);
    });
    test("Publish exactly once, release and complete", () {
      testCHS.sentMessages.clear();
      final PublishingManager pm = new PublishingManager(testCHS);
      final typed.Uint8Buffer buff = new typed.Uint8Buffer(4);
      buff[0] = 't'.codeUnitAt(0);
      buff[1] = 'e'.codeUnitAt(0);
      buff[2] = 's'.codeUnitAt(0);
      buff[3] = 't'.codeUnitAt(0);
      final int msgId = pm.publish(
          new PublicationTopic("A/rawTopic"), MqttQos.exactlyOnce, buff);
      expect(msgId, 1);
      expect(pm.publishedMessages.containsKey(1), isTrue);
      pm.handlePublishReceived(
          new MqttPublishReceivedMessage().withMessageIdentifier(msgId));
      final MqttPublishReleaseMessage pubMessRel =
      testCHS.sentMessages[1] as MqttPublishReleaseMessage;
      expect(pubMessRel.variableHeader.messageIdentifier, msgId);
      pm.handlePublishComplete(
          new MqttPublishCompleteMessage().withMessageIdentifier(msgId));
      expect(pm.publishedMessages, isEmpty);
    });
    test("Publish recieved at most once", () {
      testCHS.sentMessages.clear();
      final PublishingManager pm = new PublishingManager(testCHS);
      final int msgId = 1;
      final typed.Uint8Buffer data = new typed.Uint8Buffer(3);
      data[0] = 0;
      data[1] = 1;
      data[2] = 2;
      final MqttPublishMessage pubMess = new MqttPublishMessage()
          .withMessageIdentifier(msgId)
          .toTopic("A/rawTopic")
          .withQos(MqttQos.atMostOnce)
          .publishData(data);
      pm.handlePublish(pubMess);
      expect(pm.receivedMessages.containsKey(msgId), isFalse);
      expect(testCHS.sentMessages.isEmpty, isTrue);
    });
    test("Publish recieved at least once", () {
      testCHS.sentMessages.clear();
      final PublishingManager pm = new PublishingManager(testCHS);
      final int msgId = 1;
      final typed.Uint8Buffer data = new typed.Uint8Buffer(3);
      data[0] = 0;
      data[1] = 1;
      data[2] = 2;
      final MqttPublishMessage pubMess = new MqttPublishMessage()
          .withMessageIdentifier(msgId)
          .toTopic("A/rawTopic")
          .withQos(MqttQos.atLeastOnce)
          .publishData(data);
      pm.handlePublish(pubMess);
      expect(pm.receivedMessages.containsKey(msgId), isFalse);
      expect(testCHS.sentMessages[0].header.messageType,
          MqttMessageType.publishAck);
    });
    test("Publish recieved exactly once", () {
      testCHS.sentMessages.clear();
      final PublishingManager pm = new PublishingManager(testCHS);
      final int msgId = 1;
      final typed.Uint8Buffer data = new typed.Uint8Buffer(3);
      data[0] = 0;
      data[1] = 1;
      data[2] = 2;
      final MqttPublishMessage pubMess = new MqttPublishMessage()
          .withMessageIdentifier(msgId)
          .toTopic("A/rawTopic")
          .withQos(MqttQos.exactlyOnce)
          .publishData(data);
      pm.handlePublish(pubMess);
      expect(pm.receivedMessages.containsKey(msgId), isTrue);
      expect(testCHS.sentMessages[0].header.messageType,
          MqttMessageType.publishReceived);
    });
    test("Release recieved exactly once", () {
      testCHS.sentMessages.clear();
      final PublishingManager pm = new PublishingManager(testCHS);
      final int msgId = 1;
      final typed.Uint8Buffer data = new typed.Uint8Buffer(3);
      data[0] = 0;
      data[1] = 1;
      data[2] = 2;
      final MqttPublishMessage pubMess = new MqttPublishMessage()
          .withMessageIdentifier(msgId)
          .toTopic("A/rawTopic")
          .withQos(MqttQos.exactlyOnce)
          .publishData(data);
      pm.handlePublish(pubMess);
      expect(pm.receivedMessages.containsKey(msgId), isTrue);
      expect(testCHS.sentMessages[0].header.messageType,
          MqttMessageType.publishReceived);
      final MqttPublishReleaseMessage relMess =
      new MqttPublishReleaseMessage().withMessageIdentifier(msgId);
      pm.handlePublishRelease(relMess);
      expect(pm.receivedMessages.containsKey(msgId), isFalse);
      expect(testCHS.sentMessages[1].header.messageType,
          MqttMessageType.publishComplete);
    });
  });
}
