/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */
import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';
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
      try {
        final PublicationTopic pubTopic = new PublicationTopic(topic);
      } catch (exception) {
        expect(exception.toString(),
            "Exception: mqtt_client::Topic: rawTopic must contain at least one character");
      }
    });
    test("Max length", () {
      String topic = "";
      for (int i = 0; i < Topic.maxTopicLength + 1; i++) {
        topic += "a";
      }
      try {
        final PublicationTopic pubTopic = new PublicationTopic(topic);
      } catch (exception) {
        expect(
            exception.toString(),
            "Exception: mqtt_client::Topic: The length of the supplied rawTopic "
                "(65536) is longer than the maximum allowable (${Topic
                .maxTopicLength})");
      }
    });
    test("Wildcards", () {
      final String topic = Topic.wildcard;
      try {
        final PublicationTopic pubTopic = new PublicationTopic(topic);
      } catch (exception) {
        expect(exception.toString(),
            "Exception: mqtt_client::PublicationTopic: Cannot publish to a topic that contains MQTT topic wildcards (# or +)");
      }
      final String topic1 = Topic.multiWildcard;
      try {
        final PublicationTopic pubTopic1 = new PublicationTopic(topic1);
      } catch (exception) {
        expect(exception.toString(),
            "Exception: mqtt_client::PublicationTopic: Cannot publish to a topic that contains MQTT topic wildcards (# or +)");
      }
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
    });
  });
}
