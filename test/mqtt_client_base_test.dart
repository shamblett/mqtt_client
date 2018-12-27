/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */
import 'dart:async';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;

void main() {
  group('Exceptions', () {
    test('Client Identifier', () {
      const String clid =
          'ThisCLIDisMorethan1024characterslongvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv'
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
          'nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn'
          'nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn'
          'mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm'
          'llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll';
      final ClientIdentifierException exception =
          ClientIdentifierException(clid);
      expect(
          exception.toString(),
          'mqtt-client::ClientIdentifierException: Client id $clid is too long at ${clid.length}, '
          'Maximum ClientIdentifier length is ${Constants.maxClientIdentifierLength}');
    });
    test('Connection', () {
      const MqttConnectionState state = MqttConnectionState.disconnected;
      final ConnectionException exception = ConnectionException(state);
      expect(
          exception.toString(),
          'mqtt-client::ConnectionException: The connection must be in the Connected state in '
          'order to perform this operation. Current state is disconnected');
    });
    test('No Connection', () {
      final NoConnectionException exception =
          NoConnectionException('the message');
      expect(exception.toString(),
          'mqtt-client::NoConnectionException: the message');
    });
    test('Invalid Header', () {
      const String message = 'Corrupt Header Packet';
      final InvalidHeaderException exception = InvalidHeaderException(message);
      expect(exception.toString(),
          'mqtt-client::InvalidHeaderException: $message');
    });
    test('Invalid Message', () {
      const String message = 'Corrupt Message Packet';
      final InvalidMessageException exception =
          InvalidMessageException(message);
      expect(exception.toString(),
          'mqtt-client::InvalidMessageException: $message');
    });
    test('Invalid Payload Size', () {
      const int size = 2000;
      const int max = 1000;
      final InvalidPayloadSizeException exception =
          InvalidPayloadSizeException(size, max);
      expect(
          exception.toString(),
          'mqtt-client::InvalidPayloadSizeException: The size of the payload ($size bytes) must '
          'be equal to or greater than 0 and less than $max bytes');
    });
    test('Invalid Topic', () {
      const String message = 'Too long';
      const String topic = 'kkkk-yyyy';
      final InvalidTopicException exception =
          InvalidTopicException(message, topic);
      expect(exception.toString(),
          'mqtt-client::InvalidTopicException: Topic $topic is $message');
    });
  });

  group('Publication Topic', () {
    test('Min length', () {
      const String topic = '';
      bool raised = false;
      try {
        final PublicationTopic pubTopic = PublicationTopic(topic);
        print(pubTopic.rawTopic); // wont get here
      } on Exception catch (exception) {
        expect(exception.toString(),
            'Exception: mqtt_client::Topic: rawTopic must contain at least one character');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('Max length', () {
      bool raised = false;
      final StringBuffer sb = StringBuffer();
      for (int i = 0; i < Topic.maxTopicLength + 1; i++) {
        sb.write('a');
      }
      try {
        final String topic = sb.toString();
        final PublicationTopic pubTopic = PublicationTopic(topic);
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
      const String topic = Topic.wildcard;
      bool raised = false;
      try {
        final PublicationTopic pubTopic = PublicationTopic(topic);
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
      const String topic1 = Topic.multiWildcard;
      try {
        final PublicationTopic pubTopic1 = PublicationTopic(topic1);
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
      const String topic = 'AValidTopic';
      final PublicationTopic pubTopic = PublicationTopic(topic);
      expect(pubTopic.hasWildcards, false);
      expect(pubTopic.rawTopic, topic);
      expect(pubTopic.toString(), topic);
      final PublicationTopic pubTopic1 = PublicationTopic(topic);
      expect(pubTopic1, pubTopic);
      expect(pubTopic1.hashCode, pubTopic.hashCode);
      final PublicationTopic pubTopic2 = PublicationTopic('DDDDDDD');
      expect(pubTopic.hashCode, isNot(equals(pubTopic2.hashCode)));
    });
  });

  group('Subscription Topic', () {
    test('Invalid multiWildcard at end', () {
      const String topic = 'invalidEnding#';
      bool raised = false;
      try {
        final SubscriptionTopic subTopic = SubscriptionTopic(topic);
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
      const String topic = 'a/#/topic';
      bool raised = false;
      try {
        final SubscriptionTopic subTopic = SubscriptionTopic(topic);
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
      const String topic = 'a/##/topic';
      bool raised = false;
      try {
        final SubscriptionTopic subTopic = SubscriptionTopic(topic);
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
      const String topic = 'a/#+/topic';
      bool raised = false;
      try {
        final SubscriptionTopic subTopic = SubscriptionTopic(topic);
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
      const String topic = 'a/++/topic';
      bool raised = false;
      try {
        final SubscriptionTopic subTopic = SubscriptionTopic(topic);
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
      const String topic = 'a/frag+/topic';
      bool raised = false;
      try {
        final SubscriptionTopic subTopic = SubscriptionTopic(topic);
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
      final StringBuffer sb = StringBuffer();
      for (int i = 0; i < Topic.maxTopicLength + 1; i++) {
        sb.write('a');
      }
      bool raised = false;
      try {
        final String topic = sb.toString();
        final SubscriptionTopic subTopic = SubscriptionTopic(topic);
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
      const String topic = 'a/topic/#';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(subTopic.rawTopic, topic);
    });
    test('No Wildcards of any type is valid', () {
      const String topic = 'a/topic/with/no/wildcard/is/good';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(subTopic.rawTopic, topic);
    });
    test('No separators is valid', () {
      const String topic = 'ATopicWithNoSeparators';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(subTopic.rawTopic, topic);
    });
    test('Single level equal topics match', () {
      const String topic = 'finance';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic(topic)), isTrue);
    });
    test('MultiWildcard only topic matches any random', () {
      const String topic = '#';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('finance/ibm/closingprice')),
          isTrue);
    });
    test('MultiWildcard only topic matches topic starting with separator', () {
      const String topic = '#';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('/finance/ibm/closingprice')),
          isTrue);
    });
    test('MultiWildcard at end matches topic that does not match same depth',
        () {
      const String topic = 'finance/#';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('finance')), isTrue);
    });
    test('MultiWildcard at end matches topic with anything at Wildcard level',
        () {
      const String topic = 'finance/#';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('finance/ibm')), isTrue);
    });
    test('Single Wildcard at end matches anything in same level', () {
      const String topic = 'finance/+/closingprice';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('finance/ibm/closingprice')),
          isTrue);
    });
    test(
        'More than one single Wildcard at different levels matches topic with any value at those levels',
        () {
      const String topic = 'finance/+/closingprice/month/+';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(
          subTopic.matches(
              PublicationTopic('finance/ibm/closingprice/month/october')),
          isTrue);
    });
    test(
        'Single and MultiWildcard matches topic with any value at those levels and deeper',
        () {
      const String topic = 'finance/+/closingprice/month/#';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(
          subTopic.matches(
              PublicationTopic('finance/ibm/closingprice/month/october/2014')),
          isTrue);
    });
    test('Single Wildcard matches topic empty fragment at that point', () {
      const String topic = 'finance/+/closingprice';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(
          subTopic.matches(PublicationTopic('finance//closingprice')), isTrue);
    });
    test(
        'Single Wildcard at end matches topic with empty last fragment at that spot',
        () {
      const String topic = 'finance/ibm/+';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('finance/ibm/')), isTrue);
    });
    test('Single level non equal topics do not match', () {
      const String topic = 'finance';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('money')), isFalse);
    });
    test('Single Wildcard at end does not match topic that goes deeper', () {
      const String topic = 'finance/+';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('finance/ibm/closingprice')),
          isFalse);
    });
    test(
        'Single Wildcard at end does not match topic that does not contain anything at same level',
        () {
      const String topic = 'finance/+';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('finance')), isFalse);
    });
    test('Multi level non equal topics do not match', () {
      const String topic = 'finance/ibm/closingprice';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('some/random/topic')), isFalse);
    });
    test(
        'MultiWildcard does not match topic with difference before Wildcard level',
        () {
      const String topic = 'finance/#';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('money/ibm')), isFalse);
    });
    test('Topics differing only by case do not match', () {
      const String topic = 'finance';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(subTopic.matches(PublicationTopic('Finance')), isFalse);
    });
    test('To string', () {
      const String topic = 'finance';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(topic, subTopic.toString());
    });
    test('Wildcard', () {
      const String topic = 'finance/+';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(subTopic.hasWildcards, isTrue);
    });
    test('MultiWildcard', () {
      const String topic = 'finance/#';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(subTopic.hasWildcards, isTrue);
    });
    test('No Wildcard', () {
      const String topic = 'finance';
      final SubscriptionTopic subTopic = SubscriptionTopic(topic);
      expect(subTopic.hasWildcards, isFalse);
    });
  });

  group('ASCII String Data Convertor', () {
    test('ASCII string to byte array', () {
      const String testString = 'testStringA-Z,1-9,a-z';
      final AsciiPayloadConverter conv = AsciiPayloadConverter();
      final typed.Uint8Buffer buff = conv.convertToBytes(testString);
      expect(testString.length, buff.length);
      for (int i = 0; i < testString.length; i++) {
        expect(testString.codeUnitAt(i), buff[i]);
      }
    });
    test('Byte array to ASCII string', () {
      final List<int> input = <int>[40, 41, 42, 43];
      final typed.Uint8Buffer buff = typed.Uint8Buffer();
      buff.addAll(input);
      final AsciiPayloadConverter conv = AsciiPayloadConverter();
      final String output = conv.convertFromBytes(buff);
      expect(input.length, output.length);
      for (int i = 0; i < input.length; i++) {
        expect(input[i], output.codeUnitAt(i));
      }
    });
  });

  group('Encoding', () {
    test('Get bytes', () {
      final MqttEncoding enc = MqttEncoding();
      final typed.Uint8Buffer bytes = enc.getBytes('abc');
      expect(bytes.length, 5);
      expect(bytes[0], 0);
      expect(bytes[1], 3);
      expect(bytes[2], 'a'.codeUnits[0]);
      expect(bytes[3], 'b'.codeUnits[0]);
      expect(bytes[4], 'c'.codeUnits[0]);
    });
    test('Get byte count', () {
      final MqttEncoding enc = MqttEncoding();
      final int byteCount = enc.getByteCount('abc');
      print(byteCount);
      expect(byteCount, 5);
    });
    test('Get string', () {
      final MqttEncoding enc = MqttEncoding();
      final typed.Uint8Buffer buff = typed.Uint8Buffer(3);
      buff[0] = 'a'.codeUnits[0];
      buff[1] = 'b'.codeUnits[0];
      buff[2] = 'c'.codeUnits[0];
      final String message = enc.getString(buff);
      expect(message, 'abc');
    });
    test('Get char count valid length LSB', () {
      final MqttEncoding enc = MqttEncoding();
      final typed.Uint8Buffer buff = typed.Uint8Buffer(5);
      buff[0] = 0;
      buff[1] = 3;
      buff[2] = 'a'.codeUnits[0];
      buff[3] = 'b'.codeUnits[0];
      buff[4] = 'c'.codeUnits[0];
      final int count = enc.getCharCount(buff);
      expect(count, 3);
    });
    test('Get char count valid length MSB', () {
      final MqttEncoding enc = MqttEncoding();
      final typed.Uint8Buffer buff = typed.Uint8Buffer(2);
      buff[0] = 0xFF;
      buff[1] = 0xFF;
      final int count = enc.getCharCount(buff);
      expect(count, 65535);
    });
    test('Get char count invalid length', () {
      final MqttEncoding enc = MqttEncoding();
      bool raised = false;
      final typed.Uint8Buffer buff = typed.Uint8Buffer(1);
      buff[0] = 0;
      try {
        final int count = enc.getCharCount(buff);
        print(count); // won't get here
      } on Exception catch (exception) {
        expect(exception.toString(),
            'Exception: mqtt_client::MQTTEncoding: Length byte array must comprise 2 bytes');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('Extended characters initiate failure', () {
      final MqttEncoding enc = MqttEncoding();
      bool raised = false;
      const String extStr = '©';
      try {
        final typed.Uint8Buffer buff = enc.getBytes(extStr);
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
      final MqttClient client = MqttClient('localhost', 'abcd');
      expect(Protocol.version, Constants.mqttV31ProtocolVersion);
      expect(Protocol.name, Constants.mqttV31ProtocolName);
      client.setProtocolV311();
      expect(Protocol.version, Constants.mqttV311ProtocolVersion);
      expect(Protocol.name, Constants.mqttV311ProtocolName);
    });
    test('Byte Buffer', () {
      final typed.Uint8Buffer uBuff = typed.Uint8Buffer(10);
      final typed.Uint8Buffer uBuff1 = typed.Uint8Buffer(10);
      final MqttByteBuffer buff = MqttByteBuffer(uBuff);
      expect(buff.length, 10);
      expect(buff.position, 0);
      int tmp = buff.readByte();
      tmp = buff.readShort();
      print(tmp);
      expect(buff.position, 3);
      final typed.Uint8Buffer tmpBuff = buff.read(4);
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
      final List<int> bytes = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      final MqttByteBuffer buff1 = MqttByteBuffer.fromList(bytes);
      expect(buff1.length, 10);
      expect(buff1.position, 0);
      buff1.seek(20);
      expect(buff1.position, 10);
    });
    test('Sleep Async', () async {
      final DateTime start = DateTime.now();
      await MqttUtilities.asyncSleep(1);
      final DateTime end = DateTime.now();
      final Duration difference = end.difference(start);
      expect(difference.inSeconds, 1);
    }, skip: false);
    test('Sleep Sync', () {
      final DateTime start = DateTime.now();
      MqttUtilities.syncSleep(1);
      final DateTime end = DateTime.now();
      final Duration difference = end.difference(start);
      expect(difference.inSeconds, 1);
    });
    test('Get Qos Level', () {
      MqttQos qos = MqttUtilities.getQosLevel(0);
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
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      expect(builder.payload, isNotNull);
      expect(builder.length, 0);
    });

    test('Add buffer', () {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      final typed.Uint8Buffer buffer = typed.Uint8Buffer()
        ..addAll(<int>[1, 2, 3]);
      builder.addBuffer(buffer);
      expect(builder.length, 3);
      expect(builder.payload, buffer);
    });

    test('Add byte', () {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addByte(129);
      expect(builder.length, 1);
      expect(builder.payload.toList(), <int>[129]);
    });

    test('Add byte - overflow', () {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addByte(300);
      expect(builder.length, 1);
      expect(builder.payload.toList(), <int>[44]);
    });

    test('Add bool', () {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addBool(val: true);
      expect(builder.length, 1);
      expect(builder.payload.toList(), <int>[1]);
      builder.addBool(val: false);
      expect(builder.length, 2);
      expect(builder.payload.toList(), <int>[1, 0]);
    });

    test('Add half', () {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addHalf(18000);
      expect(builder.length, 2);
      expect(builder.payload.toList(), <int>[0x50, 0x46]);
    });

    test('Add half - overflow', () {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addHalf(65539);
      expect(builder.length, 2);
      expect(builder.payload.toList(), <int>[0x3, 0x00]);
    });

    test('Add word', () {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addWord(123456789);
      expect(builder.length, 4);
      expect(builder.payload.toList(), <int>[0x15, 0xCD, 0x5B, 0x07]);
    });

    test('Add word - overflow', () {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addWord(4294967298);
      expect(builder.length, 4);
      expect(builder.payload.toList(), <int>[0x2, 0x00, 0x00, 0x00]);
    });

    test('Add int', () {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addInt(123456789030405);
      expect(builder.length, 8);
      expect(builder.payload.toList(),
          <int>[0x05, 0x26, 0x0E, 0x86, 0x48, 0x70, 0x00, 0x00]);
    });

    test('Add string', () {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addString('Hello');
      expect(builder.length, 5);
      expect(builder.payload.toList(), <int>[72, 101, 108, 108, 111]);
    });

    test('Add unicode string', () {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addUTF16String('\u{1D11E}');
      expect(builder.length, 4);
      expect(builder.payload.toList(), <int>[0x34, 0xD8, 0x1E, 0xDD]);
    });

    test('Add emoji', () {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addUTF16String('😁');
      expect(builder.length, 4);
      expect(builder.payload.toList(), <int>[0x3D, 0xD8, 0x1, 0xDE]);
    });

    test('Add arabic', () {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addUTF16String('سلام');
      expect(builder.length, 4);
      expect(builder.payload.toList(), <int>[0x34, 0xD8, 0x1E, 0xDD]);
    });

    test('Add half double', () {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addHalfDouble(10000.5);
      expect(builder.length, 4);
      expect(builder.payload.toList(), <int>[0, 66, 28, 70]);
    });

    test('Add double', () {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addDouble(1.5e43);
      expect(builder.length, 8);
      expect(
          builder.payload.toList(), <int>[91, 150, 146, 56, 33, 134, 229, 72]);
    });
  });

  group('Cancellable async timer', () {
    test('Normal expiry', () async {
      final DateTime start = DateTime.now();
      final MqttCancellableAsyncSleep sleeper = MqttCancellableAsyncSleep(200);
      expect(sleeper.isRunning, false);
      expect(sleeper.timeout, 200);
      await sleeper.sleep();
      expect(sleeper.isRunning, false);
      final DateTime now = DateTime.now();
      expect(
          start.millisecondsSinceEpoch +
                  Duration(milliseconds: 200).inMilliseconds <=
              now.millisecondsSinceEpoch,
          true);
      expect(sleeper.isRunning, false);
    });
    test('Normal expiry - check', () async {
      final DateTime start = DateTime.now();
      final MqttCancellableAsyncSleep sleeper = MqttCancellableAsyncSleep(100);
      await sleeper.sleep();
      final DateTime now = DateTime.now();
      expect(
          start.millisecondsSinceEpoch +
                  Duration(milliseconds: 200).inMilliseconds <=
              now.millisecondsSinceEpoch,
          false);
    });

    test('Cancel', () async {
      final MqttCancellableAsyncSleep sleeper = MqttCancellableAsyncSleep(200);
      void action() {
        sleeper.cancel();
        expect(sleeper.isRunning, false);
      }

      final DateTime start = DateTime.now();
      Future<void>.delayed(Duration(milliseconds: 100), action);
      await sleeper.sleep();
      final DateTime now = DateTime.now();
      expect(now.millisecondsSinceEpoch - start.millisecondsSinceEpoch < 200,
          true);
    });
  });

  group('Connection Status', () {
    test('To String', () {
      final MqttClientConnectionStatus status = MqttClientConnectionStatus();
      expect(status.toString(),
          'Connection status is disconnected with return code noneSpecified');
      status.state = MqttConnectionState.faulted;
      status.returnCode = MqttConnectReturnCode.identifierRejected;
      expect(status.toString(),
          'Connection status is faulted with return code identifierRejected');
    });
  });
}
