/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */
import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'dart:io';

void main() {
  group("Exceptions", () {
    test("Client Identifier", () {
      final String clid = "ThisCLIDisMorethan23characterslong";
      final ClientIdentifierException exception =
      new ClientIdentifierException(clid);
      expect(
          exception.toString(),
          "mqtt-client::ClientIdentifierException: Client id $clid is too long at ${clid
              .length}, "
              "Maximum ClientIdentifier length is ${Constants
              .maxClientIdentifierLength}");
    });
    test("Connection", () {
      final ConnectionState state = ConnectionState.disconnected;
      final ConnectionException exception = new ConnectionException(state);
      expect(
          exception.toString(),
          "mqtt-client::ConnectionException: The connection must be in the Connected state in "
              "order to perform this operation. Current state is disconnected");
    });
    test("Invalid Header", () {
      final String message = "Corrupt Header Packet";
      final InvalidHeaderException exception =
      new InvalidHeaderException(message);
      expect(exception.toString(),
          "mqtt-client::InvalidHeaderException: $message");
    });
    test("Invalid Message", () {
      final String message = "Corrupt Message Packet";
      final InvalidMessageException exception =
      new InvalidMessageException(message);
      expect(exception.toString(),
          "mqtt-client::InvalidMessageException: $message");
    });
    test("Invalid Payload Size", () {
      final int size = 2000;
      final int max = 1000;
      final InvalidPayloadSizeException exception =
      new InvalidPayloadSizeException(size, max);
      expect(
          exception.toString(),
          "mqtt-client::InvalidPayloadSizeException: The size of the payload ($size bytes) must "
              "be equal to or greater than 0 and less than $max bytes");
    });
    test("Invalid Topic", () {
      final String message = "Too long";
      final String topic = "kkkk-yyyy";
      final InvalidTopicException exception =
      new InvalidTopicException(message, topic);
      expect(exception.toString(),
          "mqtt-client::InvalidTopicException: Topic $topic is $message");
    });
  });

  group("Publication Topic", () {
    test("Min length", () {
      final String topic = "";
      bool raised = false;
      try {
        final PublicationTopic pubTopic = new PublicationTopic(topic);
        print(pubTopic.rawTopic); // wont get here
      } catch (exception) {
        expect(exception.toString(),
            "Exception: mqtt_client::Topic: rawTopic must contain at least one character");
        raised = true;
      }
      expect(raised, isTrue);
    });
    test("Max length", () {
      String topic = "";
      bool raised = false;
      for (int i = 0; i < Topic.maxTopicLength + 1; i++) {
        topic += "a";
      }
      try {
        final PublicationTopic pubTopic = new PublicationTopic(topic);
        print(pubTopic.rawTopic); // wont get here
      } catch (exception) {
        expect(
            exception.toString(),
            "Exception: mqtt_client::Topic: The length of the supplied rawTopic "
                "(65536) is longer than the maximum allowable (${Topic
                .maxTopicLength})");
        raised = true;
      }
      expect(raised, isTrue);
    });
    test("Wildcards", () {
      final String topic = Topic.wildcard;
      bool raised = false;
      try {
        final PublicationTopic pubTopic = new PublicationTopic(topic);
        print(pubTopic.rawTopic); // wont get here
      } catch (exception) {
        expect(
            exception.toString(),
            "Exception: mqtt_client::PublicationTopic: Cannot publish to a topic that "
                "contains MQTT topic wildcards (# or +)");
        raised = true;
      }
      expect(raised, isTrue);
      raised = false;
      final String topic1 = Topic.multiWildcard;
      try {
        final PublicationTopic pubTopic1 = new PublicationTopic(topic1);
        print(pubTopic1.rawTopic); // wont get here
      } catch (exception) {
        expect(
            exception.toString(),
            "Exception: mqtt_client::PublicationTopic: Cannot publish to a topic "
                "that contains MQTT topic wildcards (# or +)");
        raised = true;
      }
      expect(raised, isTrue);
    });
    test("Valid", () {
      final String topic = "AValidTopic";
      final PublicationTopic pubTopic = new PublicationTopic(topic);
      expect(pubTopic.hasWildcards, false);
      expect(pubTopic.rawTopic, topic);
      expect(pubTopic.toString(), topic);
      final PublicationTopic pubTopic1 = new PublicationTopic(topic);
      expect(pubTopic1, pubTopic);
      expect(pubTopic1.hashCode, pubTopic.hashCode);
      final PublicationTopic pubTopic2 = new PublicationTopic("DDDDDDD");
      expect(pubTopic.hashCode, isNot(equals(pubTopic2.hashCode)));
    });
  });

  group("Subscription Topic", () {
    test("Invalid multiWildcard at end", () {
      final String topic = "invalidEnding#";
      bool raised = false;
      try {
        final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
        print(subTopic.rawTopic); // wont get here
      } catch (exception) {
        expect(
            exception.toString(),
            "Exception: mqtt_client::SubscriptionTopic: Topics using the # wildcard longer than 1 character must "
                "be immediately preceeded by a the rawTopic separator /");
        raised = true;
      }
      expect(raised, isTrue);
    });
    test("MultiWildcard in middle", () {
      final String topic = "a/#/topic";
      bool raised = false;
      try {
        final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
        print(subTopic.rawTopic); // wont get here
      } catch (exception) {
        expect(
            exception.toString(),
            "Exception: mqtt_client::SubscriptionTopic: The rawTopic wildcard # can "
                "only be present at the end of a topic");
        raised = true;
      }
      expect(raised, isTrue);
    });
    test("More than one MultiWildcard in single fragment", () {
      final String topic = "a/##/topic";
      bool raised = false;
      try {
        final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
        print(subTopic.rawTopic); // wont get here
      } catch (exception) {
        expect(
            exception.toString(),
            "Exception: mqtt_client::SubscriptionTopic: The rawTopic wildcard # can "
                "only be present at the end of a topic");
        raised = true;
      }
      expect(raised, isTrue);
    });
    test("More than one type of Wildcard in single fragment", () {
      final String topic = "a/#+/topic";
      bool raised = false;
      try {
        final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
        print(subTopic.rawTopic); // wont get here
      } catch (exception) {
        expect(
            exception.toString(),
            "Exception: mqtt_client::SubscriptionTopic: The rawTopic wildcard # can "
                "only be present at the end of a topic");
        raised = true;
      }
      expect(raised, isTrue);
    });
    test("More than one Wildcard in single fragment", () {
      final String topic = "a/++/topic";
      bool raised = false;
      try {
        final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
        print(subTopic.rawTopic); // wont get here
      } catch (exception) {
        expect(
            exception.toString(),
            "Exception: mqtt_client::SubscriptionTopic: rawTopic Fragment contains a "
                "wildcard but is more than one character long");
        raised = true;
      }
      expect(raised, isTrue);
    });
    test("More than just Wildcard in fragment", () {
      final String topic = "a/frag+/topic";
      bool raised = false;
      try {
        final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
        print(subTopic.rawTopic); // wont get here
      } catch (exception) {
        expect(
            exception.toString(),
            "Exception: mqtt_client::SubscriptionTopic: rawTopic Fragment contains a "
                "wildcard but is more than one character long");
        raised = true;
      }
      expect(raised, isTrue);
    });
    test("Max length", () {
      String topic = "";
      for (int i = 0; i < Topic.maxTopicLength + 1; i++) {
        topic += "a";
      }
      bool raised = false;
      try {
        final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
        print(subTopic.rawTopic); // wont get here
      } catch (exception) {
        expect(
            exception.toString(),
            "Exception: mqtt_client::Topic: The length of the supplied rawTopic "
                "(65536) is longer than the maximum allowable (${Topic
                .maxTopicLength})");
        raised = true;
      }
      expect(raised, isTrue);
    });
    test(
        "MultiWildcard at end of topic is valid when preceeded by topic separator",
            () {
          final String topic = "a/topic/#";
          final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
          expect(subTopic.rawTopic, topic);
        });
    test("No Wildcards of any type is valid", () {
      final String topic = "a/topic/with/no/wildcard/is/good";
      final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
      expect(subTopic.rawTopic, topic);
    });
    test("No separators is valid", () {
      final String topic = "ATopicWithNoSeparators";
      final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
      expect(subTopic.rawTopic, topic);
    });
    test("Single level equal topics match", () {
      final String topic = "finance";
      final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
      expect(subTopic.matches(new PublicationTopic(topic)), isTrue);
    });
    test("MultiWildcard only topic matches any random", () {
      final String topic = "#";
      final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
      expect(subTopic.matches(new PublicationTopic("finance/ibm/closingprice")),
          isTrue);
    });
    test("MultiWildcard only topic matches topic starting with separator", () {
      final String topic = "#";
      final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
      expect(
          subTopic.matches(new PublicationTopic("/finance/ibm/closingprice")),
          isTrue);
    });
    test("MultiWildcard at end matches topic that does not match same depth",
            () {
          final String topic = "finance/#";
          final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
          expect(subTopic.matches(new PublicationTopic("finance")), isTrue);
        });
    test("MultiWildcard at end matches topic with anything at Wildcard level",
            () {
          final String topic = "finance/#";
          final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
          expect(subTopic.matches(new PublicationTopic("finance/ibm")), isTrue);
        });
    test("Single Wildcard at end matches anything in same level", () {
      final String topic = "finance/+/closingprice";
      final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
      expect(subTopic.matches(new PublicationTopic("finance/ibm/closingprice")),
          isTrue);
    });
    test(
        "More than one single Wildcard at different levels matches topic with any value at those levels",
            () {
          final String topic = "finance/+/closingprice/month/+";
          final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
          expect(
              subTopic.matches(
                  new PublicationTopic(
                      "finance/ibm/closingprice/month/october")),
              isTrue);
        });
    test(
        "Single and MultiWildcard matches topic with any value at those levels and deeper",
            () {
          final String topic = "finance/+/closingprice/month/#";
          final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
          expect(
              subTopic.matches(new PublicationTopic(
                  "finance/ibm/closingprice/month/october/2014")),
              isTrue);
        });
    test("Single Wildcard matches topic empty fragment at that point", () {
      final String topic = "finance/+/closingprice";
      final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
      expect(subTopic.matches(new PublicationTopic("finance//closingprice")),
          isTrue);
    });
    test(
        "Single Wildcard at end matches topic with empty last fragment at that spot",
            () {
          final String topic = "finance/ibm/+";
          final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
          expect(
              subTopic.matches(new PublicationTopic("finance/ibm/")), isTrue);
        });
    test("Single level non equal topics do not match", () {
      final String topic = "finance";
      final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
      expect(subTopic.matches(new PublicationTopic("money")), isFalse);
    });
    test("Single Wildcard at end does not match topic that goes deeper", () {
      final String topic = "finance/+";
      final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
      expect(subTopic.matches(new PublicationTopic("finance/ibm/closingprice")),
          isFalse);
    });
    test(
        "Single Wildcard at end does not match topic that does not contain anything at same level",
            () {
          final String topic = "finance/+";
          final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
          expect(subTopic.matches(new PublicationTopic("finance")), isFalse);
        });
    test("Multi level non equal topics do not match", () {
      final String topic = "finance/ibm/closingprice";
      final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
      expect(
          subTopic.matches(new PublicationTopic("some/random/topic")), isFalse);
    });
    test(
        "MultiWildcard does not match topic with difference before Wildcard level",
            () {
          final String topic = "finance/#";
          final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
          expect(subTopic.matches(new PublicationTopic("money/ibm")), isFalse);
        });
    test("Topics differing only by case do not match", () {
      final String topic = "finance";
      final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
      expect(subTopic.matches(new PublicationTopic("Finance")), isFalse);
    });
    test("To string", () {
      final String topic = "finance";
      final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
      expect(topic, subTopic.toString());
    });
    test("Wildcard", () {
      final String topic = "finance/+";
      final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
      expect(subTopic.hasWildcards, isTrue);
    });
    test("MultiWildcard", () {
      final String topic = "finance/#";
      final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
      expect(subTopic.hasWildcards, isTrue);
    });
    test("No Wildcard", () {
      final String topic = "finance";
      final SubscriptionTopic subTopic = new SubscriptionTopic(topic);
      expect(subTopic.hasWildcards, isFalse);
    });
  });

  group("ASCII String Data Convertor", () {
    test("ASCII string to byte array", () {
      final String testString = "testStringA-Z,1-9,a-z";
      final AsciiPayloadConverter conv = new AsciiPayloadConverter();
      final typed.Uint8Buffer buff = conv.convertToBytes(testString);
      expect(testString.length, buff.length);
      for (int i = 0; i < testString.length; i++) {
        expect(testString.codeUnitAt(i), buff[i]);
      }
    });
    test("Byte array to ASCII string", () {
      final List<int> input = [40, 41, 42, 43];
      final typed.Uint8Buffer buff = new typed.Uint8Buffer();
      buff.addAll(input);
      final AsciiPayloadConverter conv = new AsciiPayloadConverter();
      final String output = conv.convertFromBytes(buff);
      expect(input.length, output.length);
      for (int i = 0; i < input.length; i++) {
        expect(input[i], output.codeUnitAt(i));
      }
    });
  });
}
