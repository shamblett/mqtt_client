/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/06/2017
 * Copyright :  S.Hamblett
 */
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'package:event_bus/event_bus.dart' as events;
import 'support/mqtt_client_test_connection_handler.dart';

// ignore_for_file: invalid_use_of_protected_member

@TestOn('vm')

// Mock classes
class MockCH extends Mock implements MqttServerConnectionHandler {}

class MockCON extends Mock implements MqttServerNormalConnection {}

void main() {
  group('Message Identifier', () {
    test('Numbering starts at 1', () {
      final dispenser = MessageIdentifierDispenser();
      expect(dispenser.getNextMessageIdentifier(), 1);
    });
    test('Numbering increments by 1', () {
      final dispenser = MessageIdentifierDispenser();
      final first = dispenser.getNextMessageIdentifier();
      final second = dispenser.getNextMessageIdentifier();
      expect(second, first + 1);
    });
    test('Numbering overflows back to 1', () {
      final dispenser = MessageIdentifierDispenser();
      dispenser.reset();
      for (var i = 0;
          i == MessageIdentifierDispenser.maxMessageIdentifier;
          i++) {
        dispenser.getNextMessageIdentifier();
      }
      // One more call should overflow us and reset us back to 1.
      expect(dispenser.getNextMessageIdentifier(), 1);
    });
  });

  group('Message registration', () {
    // Group wide
    final con = MockCON();
    final ch = MockCH();
    final clientEventBus = events.EventBus();
    final testCHNS = TestConnectionHandlerNoSend(clientEventBus);
    testCHNS.connection = con;
    ch.connection = con;
    MessageCallbackFunction cbFunc;

    test('Register for publish messages', () {
      testCHNS.registerForMessage(MqttMessageType.publish, cbFunc);
      expect(
          testCHNS.messageProcessorRegistry
              .containsKey(MqttMessageType.publish),
          isTrue);
      expect(
          testCHNS.messageProcessorRegistry[MqttMessageType.publish], cbFunc);
    });
    test('Register for publish ack messages', () {
      testCHNS.registerForMessage(MqttMessageType.publishAck, cbFunc);
      expect(
          testCHNS.messageProcessorRegistry
              .containsKey(MqttMessageType.publishAck),
          isTrue);
      expect(testCHNS.messageProcessorRegistry[MqttMessageType.publishAck],
          cbFunc);
    });
    test('Register for publish complete messages', () {
      testCHNS.registerForMessage(MqttMessageType.publishComplete, cbFunc);
      expect(
          testCHNS.messageProcessorRegistry
              .containsKey(MqttMessageType.publishComplete),
          isTrue);
      expect(testCHNS.messageProcessorRegistry[MqttMessageType.publishComplete],
          cbFunc);
    });
    test('Register for publish received messages', () {
      testCHNS.registerForMessage(MqttMessageType.publishReceived, cbFunc);
      expect(
          testCHNS.messageProcessorRegistry
              .containsKey(MqttMessageType.publishReceived),
          isTrue);
      expect(testCHNS.messageProcessorRegistry[MqttMessageType.publishReceived],
          cbFunc);
    });
    test('Register for publish release messages', () {
      testCHNS.registerForMessage(MqttMessageType.publishRelease, cbFunc);
      expect(
          testCHNS.messageProcessorRegistry
              .containsKey(MqttMessageType.publishRelease),
          isTrue);
      expect(testCHNS.messageProcessorRegistry[MqttMessageType.publishRelease],
          cbFunc);
    });
  });

  group('Publishing', () {
    test('Publish at least once', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      final buff = typed.Uint8Buffer(4);
      buff[0] = 't'.codeUnitAt(0);
      buff[1] = 'e'.codeUnitAt(0);
      buff[2] = 's'.codeUnitAt(0);
      buff[3] = 't'.codeUnitAt(0);
      final msgId = pm.publish(
          PublicationTopic('A/rawTopic'), MqttQos.atMostOnce, buff, true);
      expect(msgId, 1);
      expect(pm.publishedMessages.containsKey(1), isFalse);
      final MqttPublishMessage pubMess = testCHS.sentMessages[0];
      expect(pubMess.header.messageType, MqttMessageType.publish);
      expect(pubMess.variableHeader.messageIdentifier, 1);
      expect(pubMess.header.qos, MqttQos.atMostOnce);
      expect(pubMess.header.retain, true);
      expect(pubMess.variableHeader.topicName, 'A/rawTopic');
      expect(pubMess.payload.toString(),
          'Payload: {4 bytes={<116><101><115><116>');
    });

    test('Publish at least once', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      final buff = typed.Uint8Buffer(4);
      buff[0] = 't'.codeUnitAt(0);
      buff[1] = 'e'.codeUnitAt(0);
      buff[2] = 's'.codeUnitAt(0);
      buff[3] = 't'.codeUnitAt(0);
      pm.messageIdentifierDispenser.reset();
      final msgId =
          pm.publish(PublicationTopic('A/rawTopic'), MqttQos.atLeastOnce, buff);
      expect(msgId, 1);
      expect(pm.publishedMessages.containsKey(1), isTrue);
      final pubMess = pm.publishedMessages[1];
      expect(pubMess.header.messageType, MqttMessageType.publish);
      expect(pubMess.variableHeader.messageIdentifier, 1);
      expect(pubMess.header.qos, MqttQos.atLeastOnce);
      expect(pubMess.header.retain, false);
      expect(pubMess.variableHeader.topicName, 'A/rawTopic');
      expect(pubMess.payload.toString(),
          'Payload: {4 bytes={<116><101><115><116>');
    });
    test('Publish at exactly once', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      final buff = typed.Uint8Buffer(4);
      buff[0] = 't'.codeUnitAt(0);
      buff[1] = 'e'.codeUnitAt(0);
      buff[2] = 's'.codeUnitAt(0);
      buff[3] = 't'.codeUnitAt(0);
      final msgId =
          pm.publish(PublicationTopic('A/rawTopic'), MqttQos.exactlyOnce, buff);
      expect(msgId, 1);
      expect(pm.publishedMessages.containsKey(1), isTrue);
      final pubMess = pm.publishedMessages[1];
      expect(pubMess.header.messageType, MqttMessageType.publish);
      expect(pubMess.variableHeader.messageIdentifier, 1);
      expect(pubMess.header.qos, MqttQos.exactlyOnce);
      expect(pubMess.variableHeader.topicName, 'A/rawTopic');
      expect(pubMess.payload.toString(),
          'Payload: {4 bytes={<116><101><115><116>');
    });
    test('Publish consecutive topics', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      final buff = typed.Uint8Buffer(4);
      buff[0] = 't'.codeUnitAt(0);
      buff[1] = 'e'.codeUnitAt(0);
      buff[2] = 's'.codeUnitAt(0);
      buff[3] = 't'.codeUnitAt(0);
      final msgId1 =
          pm.publish(PublicationTopic('A/rawTopic'), MqttQos.exactlyOnce, buff);
      final msgId2 =
          pm.publish(PublicationTopic('A/rawTopic'), MqttQos.exactlyOnce, buff);
      expect(msgId2, msgId1 + 1);
    });
    test('Publish at least once and ack', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      final buff = typed.Uint8Buffer(4);
      buff[0] = 't'.codeUnitAt(0);
      buff[1] = 'e'.codeUnitAt(0);
      buff[2] = 's'.codeUnitAt(0);
      buff[3] = 't'.codeUnitAt(0);
      final msgId =
          pm.publish(PublicationTopic('A/rawTopic'), MqttQos.atLeastOnce, buff);
      expect(msgId, 1);
      pm.handlePublishAcknowledgement(
          MqttPublishAckMessage().withMessageIdentifier(msgId));
      expect(pm.publishedMessages.containsKey(1), isFalse);
    });
    test('Publish exactly once, release and complete', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      final buff = typed.Uint8Buffer(4);
      buff[0] = 't'.codeUnitAt(0);
      buff[1] = 'e'.codeUnitAt(0);
      buff[2] = 's'.codeUnitAt(0);
      buff[3] = 't'.codeUnitAt(0);
      final msgId =
          pm.publish(PublicationTopic('A/rawTopic'), MqttQos.exactlyOnce, buff);
      expect(msgId, 1);
      expect(pm.publishedMessages.containsKey(1), isTrue);
      pm.handlePublishReceived(
          MqttPublishReceivedMessage().withMessageIdentifier(msgId));
      final MqttPublishReleaseMessage pubMessRel = testCHS.sentMessages[1];
      expect(pubMessRel.variableHeader.messageIdentifier, msgId);
      pm.handlePublishComplete(
          MqttPublishCompleteMessage().withMessageIdentifier(msgId));
      expect(pm.publishedMessages, isEmpty);
    });
    test('Publish recieved at most once', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      const msgId = 1;
      final data = typed.Uint8Buffer(3);
      data[0] = 0;
      data[1] = 1;
      data[2] = 2;
      final pubMess = MqttPublishMessage()
          .withMessageIdentifier(msgId)
          .toTopic('A/rawTopic')
          .withQos(MqttQos.atMostOnce)
          .publishData(data);
      pm.handlePublish(pubMess);
      expect(pm.receivedMessages.containsKey(msgId), isFalse);
      expect(testCHS.sentMessages.isEmpty, isTrue);
    });
    test('Publish recieved at least once', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      const msgId = 1;
      final data = typed.Uint8Buffer(3);
      data[0] = 0;
      data[1] = 1;
      data[2] = 2;
      final pubMess = MqttPublishMessage()
          .withMessageIdentifier(msgId)
          .toTopic('A/rawTopic')
          .withQos(MqttQos.atLeastOnce)
          .publishData(data);
      pm.handlePublish(pubMess);
      expect(pm.receivedMessages.containsKey(msgId), isFalse);
      expect(testCHS.sentMessages[0].header.messageType,
          MqttMessageType.publishAck);
    });
    test('Publish recieved exactly once', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      const msgId = 1;
      final data = typed.Uint8Buffer(3);
      data[0] = 0;
      data[1] = 1;
      data[2] = 2;
      final pubMess = MqttPublishMessage()
          .withMessageIdentifier(msgId)
          .toTopic('A/rawTopic')
          .withQos(MqttQos.exactlyOnce)
          .publishData(data);
      pm.handlePublish(pubMess);
      expect(pm.receivedMessages.containsKey(msgId), isTrue);
      expect(testCHS.sentMessages[0].header.messageType,
          MqttMessageType.publishReceived);
    });
    test('Release recieved exactly once', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      const msgId = 1;
      final data = typed.Uint8Buffer(3);
      data[0] = 0;
      data[1] = 1;
      data[2] = 2;
      final pubMess = MqttPublishMessage()
          .withMessageIdentifier(msgId)
          .toTopic('A/rawTopic')
          .withQos(MqttQos.exactlyOnce)
          .publishData(data);
      pm.handlePublish(pubMess);
      expect(pm.receivedMessages.containsKey(msgId), isTrue);
      expect(testCHS.sentMessages[0].header.messageType,
          MqttMessageType.publishReceived);
      final relMess = MqttPublishReleaseMessage().withMessageIdentifier(msgId);
      pm.handlePublishRelease(relMess);
      expect(pm.receivedMessages.containsKey(msgId), isFalse);
      expect(testCHS.sentMessages[1].header.messageType,
          MqttMessageType.publishComplete);
    });
    test('Publish exactly once, interleaved scenario 1', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      final payload1 = MqttClientPayloadBuilder();
      payload1.addString('test1');
      final payload2 = MqttClientPayloadBuilder();
      payload2.addString('test2');
      final msgId1 = pm.publish(
          PublicationTopic('topic1'), MqttQos.exactlyOnce, payload1.payload);
      expect(msgId1, 1);
      final msgId2 = pm.publish(
          PublicationTopic('topic2'), MqttQos.exactlyOnce, payload2.payload);
      expect(msgId2, 2);
      expect(pm.publishedMessages.containsKey(msgId1), isTrue);
      expect(pm.publishedMessages.containsKey(msgId2), isTrue);
      expect(pm.publishedMessages.length, 2);
      testCHS.sentMessages.clear();
      pm.handlePublishReceived(
          MqttPublishReceivedMessage().withMessageIdentifier(msgId1));
      pm.handlePublishReceived(
          MqttPublishReceivedMessage().withMessageIdentifier(msgId2));
      expect(testCHS.sentMessages.length, 2);
      final MqttPublishReleaseMessage pubMessRel2 = testCHS.sentMessages[1];
      expect(pubMessRel2.variableHeader.messageIdentifier, msgId2);
      final MqttPublishReleaseMessage pubMessRel1 = testCHS.sentMessages[0];
      expect(pubMessRel1.variableHeader.messageIdentifier, msgId1);
      pm.handlePublishComplete(
          MqttPublishCompleteMessage().withMessageIdentifier(msgId1));
      pm.handlePublishComplete(
          MqttPublishCompleteMessage().withMessageIdentifier(msgId2));
      expect(pm.publishedMessages, isEmpty);
    });
    test('Publish exactly once, interleaved scenario 2', () {
      final clientEventBus = events.EventBus();
      final testCHS = TestConnectionHandlerSend(clientEventBus);
      final pm = PublishingManager(testCHS, clientEventBus);
      pm.messageIdentifierDispenser.reset();
      final payload1 = MqttClientPayloadBuilder();
      payload1.addString('test1');
      final payload2 = MqttClientPayloadBuilder();
      payload2.addString('test2');

      // Publish 1
      final msgId1 = pm.publish(
          PublicationTopic('topic1'), MqttQos.exactlyOnce, payload1.payload);
      expect(pm.publishedMessages.length, 1);
      expect(pm.publishedMessages.containsKey(msgId1), isTrue);
      expect(msgId1, 1);
      expect(testCHS.sentMessages.length, 1);

      // PubRel 1
      pm.handlePublishReceived(
          MqttPublishReceivedMessage().withMessageIdentifier(msgId1));
      expect(testCHS.sentMessages.length, 2);

      // Publish 2
      final msgId2 = pm.publish(
          PublicationTopic('topic2'), MqttQos.exactlyOnce, payload2.payload);
      expect(msgId2, 2);
      expect(pm.publishedMessages.length, 2);
      expect(pm.publishedMessages.containsKey(msgId2), isTrue);

      // PubRel 2
      pm.handlePublishReceived(
          MqttPublishReceivedMessage().withMessageIdentifier(msgId2));
      expect(testCHS.sentMessages.length, 4);
      final MqttPublishReleaseMessage pubMessRel1 = testCHS.sentMessages[1];
      expect(pubMessRel1.variableHeader.messageIdentifier, msgId1);
      final MqttPublishReleaseMessage pubMessRel2 = testCHS.sentMessages[3];
      expect(pubMessRel2.variableHeader.messageIdentifier, msgId2);

      // PubComp 1
      pm.handlePublishComplete(
          MqttPublishCompleteMessage().withMessageIdentifier(msgId1));
      expect(pm.publishedMessages.length, 1);
    });
  });
}
