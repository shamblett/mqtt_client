/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */
import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;

@TestOn('vm')

/// Sleep function that block asynchronous activity.
/// Time units are seconds
void syncSleep(int seconds) {
  sleep(Duration(seconds: seconds));
}

void main() {
  group('Exceptions', () {
    test('Client Identifier', () {
      const clid =
          'ThisCLIDisMorethan1024characterslongvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv'
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
          'nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn'
          'nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn'
          'mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm'
          'llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll';
      final exception = ClientIdentifierException(clid);
      expect(
          exception.toString(),
          'mqtt-client::ClientIdentifierException: Client id $clid is too long at ${clid.length}, '
          'Maximum ClientIdentifier length is ${MqttClientConstants.maxClientIdentifierLength}');
    });
    test('Connection', () {
      const state = MqttConnectionState.disconnected;
      final exception = ConnectionException(state);
      expect(
          exception.toString(),
          'mqtt-client::ConnectionException: The connection must be in the Connected state in '
          'order to perform this operation. Current state is disconnected');
    });
    test('No Connection', () {
      final exception = NoConnectionException('the message');
      expect(exception.toString(),
          'mqtt-client::NoConnectionException: the message');
    });
    test('Invalid Header', () {
      const message = 'Corrupt Header Packet';
      final exception = InvalidHeaderException(message);
      expect(exception.toString(),
          'mqtt-client::InvalidHeaderException: $message');
    });
    test('Invalid Message', () {
      const message = 'Corrupt Message Packet';
      final exception = InvalidMessageException(message);
      expect(exception.toString(),
          'mqtt-client::InvalidMessageException: $message');
    });
    test('Invalid Payload Size', () {
      const size = 2000;
      const max = 1000;
      final exception = InvalidPayloadSizeException(size, max);
      expect(
          exception.toString(),
          'mqtt-client::InvalidPayloadSizeException: The size of the payload ($size bytes) must '
          'be equal to or greater than 0 and less than $max bytes');
    });
    test('Invalid Topic', () {
      const message = 'Too long';
      const topic = 'kkkk-yyyy';
      final exception = InvalidTopicException(message, topic);
      expect(exception.toString(),
          'mqtt-client::InvalidTopicException: Topic $topic is $message');
    });
    test('Invalid Instantiation', () {
      final exception = IncorrectInstantiationException();
      expect(
          exception.toString(),
          'mqtt-client::ClientIncorrectInstantiationException: Incorrect instantiation, do not'
          'instantiate MqttClient directly, use MqttServerClient or MqttBrowserClient');
    });
  });

  group('Publication Topic', () {
    test('Min length', () {
      const topic = '';
      var raised = false;
      try {
        final pubTopic = PublicationTopic(topic);
        print(pubTopic.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(exception.toString(),
            'Exception: mqtt_client::Topic: rawTopic must contain at least one character');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('Max length', () {
      var raised = false;
      final sb = StringBuffer();
      for (var i = 0; i < Topic.maxTopicLength + 1; i++) {
        sb.write('a');
      }
      try {
        final topic = sb.toString();
        final pubTopic = PublicationTopic(topic);
        print(pubTopic.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(
            exception.toString(),
            'Exception: mqtt_client::Topic: The length of the supplied rawTopic '
            '(65536) is longer than the maximum allowable (${Topic.maxTopicLength})');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('Wildcards', () {
      const topic = Topic.wildcard;
      var raised = false;
      try {
        final pubTopic = PublicationTopic(topic);
        print(pubTopic.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(
            exception.toString(),
            'Exception: mqtt_client::PublicationTopic: Cannot publish to a topic that '
            'contains MQTT topic wildcards (# or +)');
        raised = true;
      }
      expect(raised, isTrue);
      raised = false;
      const topic1 = Topic.multiWildcard;
      try {
        final pubTopic1 = PublicationTopic(topic1);
        print(pubTopic1.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(
            exception.toString(),
            'Exception: mqtt_client::PublicationTopic: Cannot publish to a topic '
            'that contains MQTT topic wildcards (# or +)');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('Valid', () {
      const topic = 'AValidTopic';
      final pubTopic = PublicationTopic(topic);
      expect(pubTopic.hasWildcards, false);
      expect(pubTopic.rawTopic, topic);
      expect(pubTopic.toString(), topic);
      final pubTopic1 = PublicationTopic(topic);
      expect(pubTopic1, pubTopic);
      expect(pubTopic1.hashCode, pubTopic.hashCode);
      final pubTopic2 = PublicationTopic('DDDDDDD');
      expect(pubTopic.hashCode, isNot(equals(pubTopic2.hashCode)));
    });
  });

  group('Subscription Topic', () {
    test('Invalid multiWildcard at end', () {
      const topic = 'invalidEnding#';
      var raised = false;
      try {
        final subTopic = SubscriptionTopic(topic);
        print(subTopic.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(
            exception.toString(),
            'Exception: mqtt_client::SubscriptionTopic: Topics using the # wildcard longer than 1 character must '
            'be immediately preceeded by a the rawTopic separator /');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('MultiWildcard in middle', () {
      const topic = 'a/#/topic';
      var raised = false;
      try {
        final subTopic = SubscriptionTopic(topic);
        print(subTopic.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(
            exception.toString(),
            'Exception: mqtt_client::SubscriptionTopic: The rawTopic wildcard # can '
            'only be present at the end of a topic');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('More than one MultiWildcard in single fragment', () {
      const topic = 'a/##/topic';
      var raised = false;
      try {
        final subTopic = SubscriptionTopic(topic);
        print(subTopic.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(
            exception.toString(),
            'Exception: mqtt_client::SubscriptionTopic: The rawTopic wildcard # can '
            'only be present at the end of a topic');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('More than one type of Wildcard in single fragment', () {
      const topic = 'a/#+/topic';
      var raised = false;
      try {
        final subTopic = SubscriptionTopic(topic);
        print(subTopic.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(
            exception.toString(),
            'Exception: mqtt_client::SubscriptionTopic: The rawTopic wildcard # can '
            'only be present at the end of a topic');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('More than one Wildcard in single fragment', () {
      const topic = 'a/++/topic';
      var raised = false;
      try {
        final subTopic = SubscriptionTopic(topic);
        print(subTopic.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(
            exception.toString(),
            'Exception: mqtt_client::SubscriptionTopic: rawTopic Fragment contains a '
            'wildcard but is more than one character long');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('More than just Wildcard in fragment', () {
      const topic = 'a/frag+/topic';
      var raised = false;
      try {
        final subTopic = SubscriptionTopic(topic);
        print(subTopic.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(
            exception.toString(),
            'Exception: mqtt_client::SubscriptionTopic: rawTopic Fragment contains a '
            'wildcard but is more than one character long');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('Max length', () {
      final sb = StringBuffer();
      for (var i = 0; i < Topic.maxTopicLength + 1; i++) {
        sb.write('a');
      }
      var raised = false;
      try {
        final topic = sb.toString();
        final subTopic = SubscriptionTopic(topic);
        print(subTopic.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(
            exception.toString(),
            'Exception: mqtt_client::Topic: The length of the supplied rawTopic '
            '(65536) is longer than the maximum allowable (${Topic.maxTopicLength})');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test(
        'MultiWildcard at end of topic is valid when preceeded by topic separator',
        () {
      const topic = 'a/topic/#';
      final subTopic = SubscriptionTopic(topic);
      expect(subTopic.rawTopic, topic);
    });
    test('No Wildcards of any type is valid', () {
      const topic = 'a/topic/with/no/wildcard/is/good';
      final subTopic = SubscriptionTopic(topic);
      expect(subTopic.rawTopic, topic);
    });
    test('No separators is valid', () {
      const topic = 'ATopicWithNoSeparators';
      final subTopic = SubscriptionTopic(topic);
      expect(subTopic.rawTopic, topic);
    });
    test('Single level equal topics match', () {
      const topic = 'finance';
      final subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic(topic)), isTrue);
    });
    test('MultiWildcard only topic matches any random', () {
      const topic = '#';
      final subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('finance/ibm/closingprice')),
          isTrue);
    });
    test('MultiWildcard only topic matches topic starting with separator', () {
      const topic = '#';
      final subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('/finance/ibm/closingprice')),
          isTrue);
    });
    test('MultiWildcard at end matches topic that does not match same depth',
        () {
      const topic = 'finance/#';
      final subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('finance')), isTrue);
    });
    test('MultiWildcard at end matches topic with anything at Wildcard level',
        () {
      const topic = 'finance/#';
      final subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('finance/ibm')), isTrue);
    });
    test('Single Wildcard at end matches anything in same level', () {
      const topic = 'finance/+/closingprice';
      final subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('finance/ibm/closingprice')),
          isTrue);
    });
    test(
        'More than one single Wildcard at different levels matches topic with any value at those levels',
        () {
      const topic = 'finance/+/closingprice/month/+';
      final subTopic = SubscriptionTopic(topic);
      expect(
          subTopic.matches(
              PublicationTopic('finance/ibm/closingprice/month/october')),
          isTrue);
    });
    test(
        'Single and MultiWildcard matches topic with any value at those levels and deeper',
        () {
      const topic = 'finance/+/closingprice/month/#';
      final subTopic = SubscriptionTopic(topic);
      expect(
          subTopic.matches(
              PublicationTopic('finance/ibm/closingprice/month/october/2014')),
          isTrue);
    });
    test('Single Wildcard matches topic empty fragment at that point', () {
      const topic = 'finance/+/closingprice';
      final subTopic = SubscriptionTopic(topic);
      expect(
          subTopic.matches(PublicationTopic('finance//closingprice')), isTrue);
    });
    test(
        'Single Wildcard at end matches topic with empty last fragment at that spot',
        () {
      const topic = 'finance/ibm/+';
      final subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('finance/ibm/')), isTrue);
    });
    test('Single level non equal topics do not match', () {
      const topic = 'finance';
      final subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('money')), isFalse);
    });
    test('Single Wildcard at end does not match topic that goes deeper', () {
      const topic = 'finance/+';
      final subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('finance/ibm/closingprice')),
          isFalse);
    });
    test(
        'Single Wildcard at end does not match topic that does not contain anything at same level',
        () {
      const topic = 'finance/+';
      final subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('finance')), isFalse);
    });
    test('Multi level non equal topics do not match', () {
      const topic = 'finance/ibm/closingprice';
      final subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('some/random/topic')), isFalse);
    });
    test(
        'MultiWildcard does not match topic with difference before Wildcard level',
        () {
      const topic = 'finance/#';
      final subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('money/ibm')), isFalse);
    });
    test('Topics differing only by case do not match', () {
      const topic = 'finance';
      final subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('Finance')), isFalse);
    });
    test('To string', () {
      const topic = 'finance';
      final subTopic = SubscriptionTopic(topic);
      expect(topic, subTopic.toString());
    });
    test('Wildcard', () {
      const topic = 'finance/+';
      final subTopic = SubscriptionTopic(topic);
      expect(subTopic.hasWildcards, isTrue);
    });
    test('MultiWildcard', () {
      const topic = 'finance/#';
      final subTopic = SubscriptionTopic(topic);
      expect(subTopic.hasWildcards, isTrue);
    });
    test('No Wildcard', () {
      const topic = 'finance';
      final subTopic = SubscriptionTopic(topic);
      expect(subTopic.hasWildcards, isFalse);
    });
  });

  group('ASCII String Data Convertor', () {
    test('ASCII string to byte array', () {
      const testString = 'testStringA-Z,1-9,a-z';
      final conv = AsciiPayloadConverter();
      final buff = conv.convertToBytes(testString);
      expect(testString.length, buff.length);
      for (var i = 0; i < testString.length; i++) {
        expect(testString.codeUnitAt(i), buff[i]);
      }
    });
    test('Byte array to ASCII string', () {
      final input = <int>[40, 41, 42, 43];
      final buff = typed.Uint8Buffer();
      buff.addAll(input);
      final conv = AsciiPayloadConverter();
      final output = conv.convertFromBytes(buff);
      expect(input.length, output.length);
      for (var i = 0; i < input.length; i++) {
        expect(input[i], output.codeUnitAt(i));
      }
    });
  });

  group('Encoding', () {
    test('Get bytes', () {
      final enc = MqttEncoding();
      final bytes = enc.getBytes('abc');
      expect(bytes.length, 5);
      expect(bytes[0], 0);
      expect(bytes[1], 3);
      expect(bytes[2], 'a'.codeUnits[0]);
      expect(bytes[3], 'b'.codeUnits[0]);
      expect(bytes[4], 'c'.codeUnits[0]);
    });
    test('Get byte count', () {
      final enc = MqttEncoding();
      final byteCount = enc.getByteCount('abc');
      print(byteCount);
      expect(byteCount, 5);
    });
    test('Get string', () {
      final enc = MqttEncoding();
      final buff = typed.Uint8Buffer(3);
      buff[0] = 'a'.codeUnits[0];
      buff[1] = 'b'.codeUnits[0];
      buff[2] = 'c'.codeUnits[0];
      final message = enc.getString(buff);
      expect(message, 'abc');
    });
    test('Get char count valid length LSB', () {
      final enc = MqttEncoding();
      final buff = typed.Uint8Buffer(5);
      buff[0] = 0;
      buff[1] = 3;
      buff[2] = 'a'.codeUnits[0];
      buff[3] = 'b'.codeUnits[0];
      buff[4] = 'c'.codeUnits[0];
      final count = enc.getCharCount(buff);
      expect(count, 3);
    });
    test('Get char count valid length MSB', () {
      final enc = MqttEncoding();
      final buff = typed.Uint8Buffer(2);
      buff[0] = 0xFF;
      buff[1] = 0xFF;
      final count = enc.getCharCount(buff);
      expect(count, 65535);
    });
    test('Get char count invalid length', () {
      final enc = MqttEncoding();
      var raised = false;
      final buff = typed.Uint8Buffer(1);
      buff[0] = 0;
      try {
        final count = enc.getCharCount(buff);
        print(count); // won't get here
      } on Exception catch (exception) {
        expect(exception.toString(),
            'Exception: mqtt_client::MQTTEncoding: Length byte array must comprise 2 bytes');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('Extended characters initiate failure', () {
      final enc = MqttEncoding();
      var raised = false;
      const extStr = '©';
      try {
        final buff = enc.getBytes(extStr);
        print(buff.toString()); // won't get here
      } on Exception catch (exception) {
        expect(
            exception.toString(),
            'Exception: mqtt_client::MQTTEncoding: The input string has extended '
            'UTF characters, which are not supported');
        raised = true;
      }
      expect(raised, isTrue);
    });
  });

  group('Utility', () {
    test('Protocol', () {
      final client = MqttClient('localhost', 'abcd');
      expect(Protocol.version, MqttClientConstants.mqttV31ProtocolVersion);
      expect(Protocol.name, MqttClientConstants.mqttV31ProtocolName);
      client.setProtocolV311();
      expect(Protocol.version, MqttClientConstants.mqttV311ProtocolVersion);
      expect(Protocol.name, MqttClientConstants.mqttV311ProtocolName);
    });
    test('Byte Buffer', () {
      final uBuff = typed.Uint8Buffer(10);
      final uBuff1 = typed.Uint8Buffer(10);
      final buff = MqttByteBuffer(uBuff);
      expect(buff.length, 10);
      expect(buff.position, 0);
      var tmp = buff.readByte();
      tmp = buff.readShort();
      print(tmp);
      expect(buff.position, 3);
      final tmpBuff = buff.read(4);
      expect(tmpBuff.length, 4);
      expect(buff.position, 7);
      buff.writeByte(1);
      buff.writeShort(2);
      expect(buff.position, 10);
      buff.write(uBuff);
      expect(buff.length, 20);
      expect(buff.position, 20);
      buff.buffer = null;
      buff.write(uBuff1);
      expect(buff.length, 10);
      expect(buff.position, 10);
      final bytes = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      final buff1 = MqttByteBuffer.fromList(bytes);
      expect(buff1.length, 10);
      expect(buff1.position, 0);
      buff1.seek(20);
      expect(buff1.position, 10);
    });
    test('Byte Buffer To String', () {
      final uBuff = typed.Uint8Buffer();
      final buff = MqttByteBuffer(uBuff);
      expect(buff.toString(), 'null or empty');
      final bytes = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      final buff1 = MqttByteBuffer.fromList(bytes);
      expect(buff1.toString(), '[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]');
    });
    test('Sleep Async', () async {
      final start = DateTime.now();
      await MqttUtilities.asyncSleep(1);
      final end = DateTime.now();
      final difference = end.difference(start);
      expect(difference.inSeconds, 1);
    });
    test('Sleep Sync', () {
      final start = DateTime.now();
      syncSleep(1);
      final end = DateTime.now();
      final difference = end.difference(start);
      expect(difference.inSeconds, 1);
    });
    test('Get Qos Level', () {
      var qos = MqttUtilities.getQosLevel(0);
      expect(qos, MqttQos.atMostOnce);
      qos = MqttUtilities.getQosLevel(1);
      expect(qos, MqttQos.atLeastOnce);
      qos = MqttUtilities.getQosLevel(2);
      expect(qos, MqttQos.exactlyOnce);
      qos = MqttUtilities.getQosLevel(0x80);
      expect(qos, MqttQos.failure);
      qos = MqttUtilities.getQosLevel(0x55);
      expect(qos, MqttQos.reserved1);
    });
  });

  group('Payload builder', () {
    test('Construction', () {
      final builder = MqttClientPayloadBuilder();
      expect(builder.payload, isNotNull);
      expect(builder.length, 0);
    });

    test('Add buffer', () {
      final builder = MqttClientPayloadBuilder();
      final buffer = typed.Uint8Buffer()..addAll(<int>[1, 2, 3]);
      builder.addBuffer(buffer);
      expect(builder.length, 3);
      expect(builder.payload, buffer);
    });

    test('Add byte', () {
      final builder = MqttClientPayloadBuilder();
      builder.addByte(129);
      expect(builder.length, 1);
      expect(builder.payload!.toList(), <int>[129]);
    });

    test('Add byte - overflow', () {
      final builder = MqttClientPayloadBuilder();
      builder.addByte(300);
      expect(builder.length, 1);
      expect(builder.payload!.toList(), <int>[44]);
    });

    test('Add bool', () {
      final builder = MqttClientPayloadBuilder();
      builder.addBool(val: true);
      expect(builder.length, 1);
      expect(builder.payload!.toList(), <int>[1]);
      builder.addBool(val: false);
      expect(builder.length, 2);
      expect(builder.payload!.toList(), <int>[1, 0]);
    });

    test('Add half', () {
      final builder = MqttClientPayloadBuilder();
      builder.addHalf(18000);
      expect(builder.length, 2);
      expect(builder.payload!.toList(), <int>[0x50, 0x46]);
    });

    test('Add half - overflow', () {
      final builder = MqttClientPayloadBuilder();
      builder.addHalf(65539);
      expect(builder.length, 2);
      expect(builder.payload!.toList(), <int>[0x3, 0x00]);
    });

    test('Add word', () {
      final builder = MqttClientPayloadBuilder();
      builder.addWord(123456789);
      expect(builder.length, 4);
      expect(builder.payload!.toList(), <int>[0x15, 0xCD, 0x5B, 0x07]);
    });

    test('Add word - overflow', () {
      final builder = MqttClientPayloadBuilder();
      builder.addWord(4294967298);
      expect(builder.length, 4);
      expect(builder.payload!.toList(), <int>[0x2, 0x00, 0x00, 0x00]);
    });

    test('Add int', () {
      final builder = MqttClientPayloadBuilder();
      builder.addInt(123456789030405);
      expect(builder.length, 8);
      expect(builder.payload!.toList(),
          <int>[0x05, 0x26, 0x0E, 0x86, 0x48, 0x70, 0x00, 0x00]);
    });

    test('Add string', () {
      final builder = MqttClientPayloadBuilder();
      builder.addString('Hello');
      expect(builder.length, 5);
      expect(builder.payload!.toList(), <int>[72, 101, 108, 108, 111]);
    });

    test('Add unicode string', () {
      final builder = MqttClientPayloadBuilder();
      builder.addUTF16String('\u{1D11E}');
      expect(builder.length, 4);
      expect(builder.payload!.toList(), <int>[0x34, 0xD8, 0x1E, 0xDD]);
    });

    test('Add emoji', () {
      final builder = MqttClientPayloadBuilder();
      builder.addUTF16String('😁');
      expect(builder.length, 4);
      expect(builder.payload!.toList(), <int>[0x3D, 0xD8, 0x1, 0xDE]);
    });

    test('Add arabic', () {
      final builder = MqttClientPayloadBuilder();
      const arabic = 'سلام';
      builder.addUTF16String(arabic);
      expect(builder.length, 8);
      expect(builder.payload!.toList(),
          <int>[0x33, 0x06, 0x44, 0x06, 0x27, 0x06, 0x45, 0x06]);
    });

    test('Add arabic string', () {
      final builder = MqttClientPayloadBuilder();
      const arabic = 'این یک پیام تستی هستش';
      builder.addString(arabic);
      expect(builder.length, 38);
      expect(builder.payload!.toList(), <int>[
        0x27,
        0x06,
        0xCC,
        0x06,
        0x46,
        0x06,
        0x20,
        0xCC,
        0x06,
        0xA9,
        0x06,
        0x20,
        0x7E,
        0x06,
        0xCC,
        0x06,
        0x27,
        0x06,
        0x45,
        0x06,
        0x20,
        0x2A,
        0x06,
        0x33,
        0x06,
        0x2A,
        0x06,
        0xCC,
        0x06,
        0x020,
        0x47,
        0x06,
        0x33,
        0x06,
        0x2A,
        0x06,
        0x34,
        0x06
      ]);
    });

    test('Add UTF8 string', () {
      final builder = MqttClientPayloadBuilder();
      builder.addUTF8String(json
          .encode(<String, String>{'type': 'msgText', 'data': 'تست 😀 😁 '}));
      expect(builder.length, 45);
      expect(builder.payload!.toList(), <int>[
        123,
        34,
        116,
        121,
        112,
        101,
        34,
        58,
        34,
        109,
        115,
        103,
        84,
        101,
        120,
        116,
        34,
        44,
        34,
        100,
        97,
        116,
        97,
        34,
        58,
        34,
        216,
        170,
        216,
        179,
        216,
        170,
        32,
        240,
        159,
        152,
        128,
        32,
        240,
        159,
        152,
        129,
        32,
        34,
        125
      ]);
    });

    test('Add half double', () {
      final builder = MqttClientPayloadBuilder();
      builder.addHalfDouble(10000.5);
      expect(builder.length, 4);
      expect(builder.payload!.toList(), <int>[0, 66, 28, 70]);
    });

    test('Add double', () {
      final builder = MqttClientPayloadBuilder();
      builder.addDouble(1.5e43);
      expect(builder.length, 8);
      expect(
          builder.payload!.toList(), <int>[91, 150, 146, 56, 33, 134, 229, 72]);
    });

    test('Clear', () {
      final builder = MqttClientPayloadBuilder();
      builder.addString('Hello');
      expect(builder.length, 5);
      builder.clear();
      expect(builder.length, 0);
    });
  });

  group('Cancellable async timer', () {
    test('Normal expiry', () async {
      final start = DateTime.now();
      final sleeper = MqttCancellableAsyncSleep(200);
      expect(sleeper.isRunning, false);
      expect(sleeper.timeout, 200);
      await sleeper.sleep();
      expect(sleeper.isRunning, false);
      final now = DateTime.now();
      expect(
          start.millisecondsSinceEpoch +
                  const Duration(milliseconds: 200).inMilliseconds <=
              now.millisecondsSinceEpoch,
          true);
      expect(sleeper.isRunning, false);
    });
    test('Normal expiry - check', () async {
      final start = DateTime.now();
      final sleeper = MqttCancellableAsyncSleep(100);
      await sleeper.sleep();
      final now = DateTime.now();
      expect(
          start.millisecondsSinceEpoch +
                  const Duration(milliseconds: 200).inMilliseconds <=
              now.millisecondsSinceEpoch,
          false);
    });

    test('Cancel', () async {
      final sleeper = MqttCancellableAsyncSleep(200);
      void action() {
        sleeper.cancel();
        expect(sleeper.isRunning, false);
      }

      final start = DateTime.now();
      Future<void>.delayed(const Duration(milliseconds: 100), action);
      await sleeper.sleep();
      final now = DateTime.now();
      expect(now.millisecondsSinceEpoch - start.millisecondsSinceEpoch < 200,
          true);
    });
  });

  group('Connection Status', () {
    test('To String', () {
      final status = MqttClientConnectionStatus();
      expect(
          status.toString(),
          'Connection status is disconnected with return code of noneSpecified and '
          'a disconnection origin of none');
      status.state = MqttConnectionState.faulted;
      status.returnCode = MqttConnectReturnCode.identifierRejected;
      expect(
          status.toString(),
          'Connection status is faulted with return code of identifierRejected '
          'and a disconnection origin of none');
    });
  });

  group('Mqtt Client', () {
    test('Invalid instantiation', () async {
      var ok = false;
      try {
        final client = MqttClient('aaaa', 'bbbb');
        await client.connect();
      } on IncorrectInstantiationException {
        ok = true;
      }
      expect(ok, isTrue);
    });
    test('Client Id ', (){
        final client = MqttClient('aaaa', 'bbbb');
        expect(client.getConnectMessage('username', 'password').payload.clientIdentifier, 'bbbb');
        final userConnect = MqttConnectMessage().withClientIdentifier('cccc');
        client.connectionMessage = userConnect;
        expect(client.getConnectMessage('username', 'password').payload.clientIdentifier, 'cccc');
    });
  });

  group('Logging', () {
    test('Logging off', () {
      MqttLogger.clientId = 1;
      MqttLogger.testMode = true;
      MqttLogger.log('No output');
      expect(MqttLogger.testOutput, '');
    });
    test('Logging on - normal', () {
      MqttLogger.clientId = 2;
      MqttLogger.testMode = true;
      MqttLogger.loggingOn = true;
      MqttLogger.log('Some output');
      expect(MqttLogger.testOutput.isNotEmpty, isTrue);
      expect(MqttLogger.testOutput.contains('Some output'), isTrue);
    });
    test('Logging on - optimised', () {
      MqttLogger.clientId = 3;
      MqttLogger.testMode = true;
      MqttLogger.loggingOn = true;
      final message = MqttSubscribeAckMessage();
      MqttLogger.log('Some output - ', message);
      expect(MqttLogger.testOutput.isNotEmpty, isTrue);
      expect(MqttLogger.testOutput.contains('Some output'), isTrue);
      expect(MqttLogger.testOutput.contains('MqttMessageType.subscribeAck'),
          isTrue);
    });
  });
}
