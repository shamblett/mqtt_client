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

class MockCON extends Mock implements MqttConnection {}

final TestConnectionHandler testCH = new TestConnectionHandler();
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
    testCH.connection = con;
    ch.connection = con;
    MessageCallbackFunction cbFunc;

    test("Register for publish messages", () {
      testCH.registerForMessage(MqttMessageType.publish, cbFunc);
      expect(
          testCH.messageProcessorRegistry
              .containsKey(MqttMessageType.publish),
          isTrue);
      expect(
          testCH.messageProcessorRegistry[MqttMessageType.publish], cbFunc);
    });
    test("Register for publish ack messages", () {
      testCH.registerForMessage(MqttMessageType.publishAck, cbFunc);
      expect(
          testCH.messageProcessorRegistry
              .containsKey(MqttMessageType.publishAck),
          isTrue);
      expect(
          testCH.messageProcessorRegistry[MqttMessageType.publishAck], cbFunc);
    });
    test("Register for publish complete messages", () {
      testCH.registerForMessage(MqttMessageType.publishComplete, cbFunc);
      expect(
          testCH.messageProcessorRegistry
              .containsKey(MqttMessageType.publishComplete),
          isTrue);
      expect(
          testCH.messageProcessorRegistry[MqttMessageType.publishComplete],
          cbFunc);
    });
    test("Register for publish received messages", () {
      testCH.registerForMessage(MqttMessageType.publishReceived, cbFunc);
      expect(
          testCH.messageProcessorRegistry
              .containsKey(MqttMessageType.publishReceived),
          isTrue);
      expect(
          testCH.messageProcessorRegistry[MqttMessageType.publishReceived],
          cbFunc);
    });
    test("Register for publish release messages", () {
      testCH.registerForMessage(MqttMessageType.publishRelease, cbFunc);
      expect(
          testCH.messageProcessorRegistry
              .containsKey(MqttMessageType.publishRelease),
          isTrue);
      expect(
          testCH.messageProcessorRegistry[MqttMessageType.publishRelease],
          cbFunc);
    });
  });

  group("Publishing", () {
    test("Publish", () {
      final PublishingManager pm = new PublishingManager(testCH);
      final typed.Uint8Buffer buff = new typed.Uint8Buffer(4);
      buff[0] = 't'.codeUnitAt(0);
      buff[1] = 'e'.codeUnitAt(0);
      buff[2] = 's'.codeUnitAt(0);
      buff[3] = 't'.codeUnitAt(0);
      final int msgId = pm.publish(
          new PublicationTopic("A/rawTopic"), MqttQos.atMostOnce, buff);
      expect(msgId, 1);
      expect(pm.publishedMessages.containsKey(1), isFalse);
    });
  });
}
