/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/06/2017
 * Copyright :  S.Hamblett
 */
import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:typed_data/typed_data.dart' as typed;

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
}
