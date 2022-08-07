/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

@TestOn('vm')

import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;

/// Helper methods for test message serialization and deserialization
class MessageSerializationHelper {
  /// Invokes the serialization of a message to get an array of bytes that represent the message.
  static typed.Uint8Buffer getMessageBytes(MqttMessage msg) {
    final buff = typed.Uint8Buffer();
    final ms = MqttByteBuffer(buff);
    msg.writeTo(ms);
    ms.seek(0);
    final msgBytes = ms.read(ms.length);
    return msgBytes;
  }
}

void main() {
  group('Header', () {
    /// Test helper method to call Get Remaining Bytes with a specific value
    typed.Uint8Buffer callGetRemainingBytesWithValue(int value) {
      // validates a payload size of a single byte using the example values supplied in the MQTT spec
      final header = MqttHeader();
      header.messageSize = value;
      return header.getRemainingLengthBytes();
    }

    /// Creates byte array header with a single byte length
    /// byte1 - the first header byte
    /// length - the length byte
    typed.Uint8Buffer getHeaderBytes(int byte1, int length) {
      final tmp = typed.Uint8Buffer(2);
      tmp[0] = byte1;
      tmp[1] = length;
      return tmp;
    }

    /// Gets the MQTT header from a byte arrayed header.
    MqttHeader getMqttHeader(typed.Uint8Buffer headerBytes) {
      final buff = MqttByteBuffer(headerBytes);
      return MqttHeader.fromByteBuffer(buff);
    }

    test('Single byte payload size', () {
      // Validates a payload size of a single byte using the example values supplied in the MQTT spec
      final returnedBytes = callGetRemainingBytesWithValue(127);
      // Check that the count of bytes returned is only 1, and the value of the byte is correct.
      expect(returnedBytes.length, 1);
      expect(returnedBytes[0], 127);
    });
    test('Double byte payload size lower boundary 128', () {
      final returnedBytes = callGetRemainingBytesWithValue(128);
      expect(returnedBytes.length, 2);
      expect(returnedBytes[0], 0x80);
      expect(returnedBytes[1], 0x01);
    });
    test('Double byte payload size upper boundary 16383', () {
      final returnedBytes = callGetRemainingBytesWithValue(16383);
      expect(returnedBytes.length, 2);
      expect(returnedBytes[0], 0xFF);
      expect(returnedBytes[1], 0x7F);
    });
    test('Triple byte payload size lower boundary 16384', () {
      final returnedBytes = callGetRemainingBytesWithValue(16384);
      expect(returnedBytes.length, 3);
      expect(returnedBytes[0], 0x80);
      expect(returnedBytes[1], 0x80);
      expect(returnedBytes[2], 0x01);
    });
    test('Triple byte payload size upper boundary 2097151', () {
      final returnedBytes = callGetRemainingBytesWithValue(2097151);
      expect(returnedBytes.length, 3);
      expect(returnedBytes[0], 0xFF);
      expect(returnedBytes[1], 0xFF);
      expect(returnedBytes[2], 0x7F);
    });
    test('Quadruple byte payload size lower boundary 2097152', () {
      final returnedBytes = callGetRemainingBytesWithValue(2097152);
      expect(returnedBytes.length, 4);
      expect(returnedBytes[0], 0x80);
      expect(returnedBytes[1], 0x80);
      expect(returnedBytes[2], 0x80);
      expect(returnedBytes[3], 0x01);
    });
    test('Quadruple byte payload size upper boundary 268435455', () {
      final returnedBytes = callGetRemainingBytesWithValue(268435455);
      expect(returnedBytes.length, 4);
      expect(returnedBytes[0], 0xFF);
      expect(returnedBytes[1], 0xFF);
      expect(returnedBytes[2], 0xFF);
      expect(returnedBytes[3], 0x7F);
    });
    test('Payload size out of upper range', () {
      final header = MqttHeader();
      var raised = false;
      header.messageSize = 2;
      try {
        header.messageSize = 268435456;
      } on Exception {
        raised = true;
      }
      expect(raised, isTrue);
      expect(header.messageSize, 2);
    });
    test('Payload size out of lower range', () {
      final header = MqttHeader();
      var raised = false;
      header.messageSize = 2;
      try {
        header.messageSize = -1;
      } on Exception {
        raised = true;
      }
      expect(raised, isTrue);
      expect(header.messageSize, 2);
    });
    test('Duplicate', () {
      final header = MqttHeader().isDuplicate();
      expect(header.duplicate, isTrue);
    });
    test('Qos', () {
      final header = MqttHeader().withQos(MqttQos.atMostOnce);
      expect(header.qos, MqttQos.atMostOnce);
    });
    test('Message type', () {
      final header = MqttHeader().asType(MqttMessageType.publishComplete);
      expect(header.messageType, MqttMessageType.publishComplete);
    });
    test('Retain', () {
      final header = MqttHeader().shouldBeRetained();
      expect(header.retain, isTrue);
    });
    test('Round trip', () {
      final inputHeader = MqttHeader();
      inputHeader.duplicate = true;
      inputHeader.retain = false;
      inputHeader.messageSize = 1;
      inputHeader.messageType = MqttMessageType.connect;
      inputHeader.qos = MqttQos.atLeastOnce;
      final buffer = MqttByteBuffer(typed.Uint8Buffer());
      inputHeader.writeTo(1, buffer);
      buffer.reset();
      final outputHeader = MqttHeader.fromByteBuffer(buffer);
      expect(inputHeader.duplicate, outputHeader.duplicate);
      expect(inputHeader.retain, outputHeader.retain);
      expect(inputHeader.messageSize, outputHeader.messageSize);
      expect(inputHeader.messageType, outputHeader.messageType);
      expect(inputHeader.qos, outputHeader.qos);
    });
    test('Corrupt header', () {
      final inputHeader = MqttHeader();
      inputHeader.duplicate = true;
      inputHeader.retain = false;
      inputHeader.messageSize = 268435455;
      inputHeader.messageType = MqttMessageType.connect;
      inputHeader.qos = MqttQos.atLeastOnce;
      final buffer = MqttByteBuffer(typed.Uint8Buffer());
      inputHeader.writeTo(268435455, buffer);
      // Fudge the header by making the last bit of the 4th message size byte a 1, therefore making the header
      // invalid because the last bit of the 4th size byte should always be 0 (according to the spec). It's how
      // we know to stop processing the header when reading a full message).
      buffer.seek(0);
      buffer.readByte();
      buffer.readByte();
      buffer.readByte();
      buffer.writeByte(buffer.readByte() | 0xFF);
      var raised = false;
      buffer.seek(0);
      try {
        final outputHeader = MqttHeader.fromByteBuffer(buffer);
        print(outputHeader.toString());
      } on Exception {
        raised = true;
      }
      expect(raised, true);
    });
    test('Corrupt header undersize', () {
      final buffer = MqttByteBuffer(typed.Uint8Buffer());
      buffer.writeByte(0);
      buffer.seek(0);
      var raised = false;
      try {
        final outputHeader = MqttHeader.fromByteBuffer(buffer);
        print(outputHeader.toString());
      } on Exception {
        raised = true;
      }
      expect(raised, true);
    });
    test('QOS at most once', () {
      final headerBytes = getHeaderBytes(1, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.qos, MqttQos.atMostOnce);
    });
    test('QOS at least once', () {
      final headerBytes = getHeaderBytes(2, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.qos, MqttQos.atLeastOnce);
    });
    test('QOS exactly once', () {
      final headerBytes = getHeaderBytes(4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.qos, MqttQos.exactlyOnce);
    });
    test('QOS reserved1', () {
      final headerBytes = getHeaderBytes(6, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.qos, MqttQos.reserved1);
    });
    test('Message type reserved1', () {
      final headerBytes = getHeaderBytes(0, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.reserved1);
    });
    test('Message type connect', () {
      final headerBytes = getHeaderBytes(1 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.connect);
    });
    test('Message type connect ack', () {
      final headerBytes = getHeaderBytes(2 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.connectAck);
    });
    test('Message type publish', () {
      final headerBytes = getHeaderBytes(3 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.publish);
    });
    test('Message type publish ack', () {
      final headerBytes = getHeaderBytes(4 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.publishAck);
    });
    test('Message type publish received', () {
      final headerBytes = getHeaderBytes(5 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.publishReceived);
    });
    test('Message type publish release', () {
      final headerBytes = getHeaderBytes(6 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.publishRelease);
    });
    test('Message type publish complete', () {
      final headerBytes = getHeaderBytes(7 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.publishComplete);
    });
    test('Message type subscribe', () {
      final headerBytes = getHeaderBytes(8 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.subscribe);
    });
    test('Message type subscribe ack', () {
      final headerBytes = getHeaderBytes(9 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.subscribeAck);
    });
    test('Message type subscribe', () {
      final headerBytes = getHeaderBytes(8 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.subscribe);
    });
    test('Message type unsubscribe', () {
      final headerBytes = getHeaderBytes(10 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.unsubscribe);
    });
    test('Message type unsubscribe ack', () {
      final headerBytes = getHeaderBytes(11 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.unsubscribeAck);
    });
    test('Message type ping request', () {
      final headerBytes = getHeaderBytes(12 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.pingRequest);
    });
    test('Message type ping response', () {
      final headerBytes = getHeaderBytes(13 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.pingResponse);
    });
    test('Message type disconnect', () {
      final headerBytes = getHeaderBytes(14 << 4, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.disconnect);
    });
    test('Duplicate true', () {
      final headerBytes = getHeaderBytes(8, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.duplicate, isTrue);
    });
    test('Duplicate false', () {
      final headerBytes = getHeaderBytes(0, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.duplicate, isFalse);
    });
    test('Retain true', () {
      final headerBytes = getHeaderBytes(1, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.retain, isTrue);
    });
    test('Retain false', () {
      final headerBytes = getHeaderBytes(0, 0);
      final header = getMqttHeader(headerBytes);
      expect(header.retain, isFalse);
    });
  });

  group('Connect Flags', () {
    /// Gets the connect flags for a specific byte value
    MqttConnectFlags getConnectFlags(int value) {
      final tmp = typed.Uint8Buffer(1);
      tmp[0] = value;
      final buffer = MqttByteBuffer(tmp);
      return MqttConnectFlags.fromByteBuffer(buffer);
    }

    test('WillQos - AtMostOnce', () {
      expect(getConnectFlags(0).willQos, MqttQos.atMostOnce);
    });
    test('WillQos - AtLeastOnce', () {
      expect(getConnectFlags(8).willQos, MqttQos.atLeastOnce);
    });
    test('WillQos - ExactlyOnce', () {
      expect(getConnectFlags(16).willQos, MqttQos.exactlyOnce);
    });
    test('WillQos - Reserved1', () {
      expect(getConnectFlags(24).willQos, MqttQos.reserved1);
    });
    test('Reserved1 true', () {
      expect(getConnectFlags(1).reserved1, isTrue);
    });
    test('Reserved1 false', () {
      expect(getConnectFlags(0).reserved1, isFalse);
    });
    test('Passwordflag true', () {
      expect(getConnectFlags(64).passwordFlag, isTrue);
    });
    test('Passwordflag false', () {
      expect(getConnectFlags(0).passwordFlag, isFalse);
    });
    test('Usernameflag true', () {
      expect(getConnectFlags(128).usernameFlag, isTrue);
    });
    test('Usernameflag false', () {
      expect(getConnectFlags(0).usernameFlag, isFalse);
    });
    test('Cleanstart true', () {
      expect(getConnectFlags(2).cleanStart, isTrue);
    });
    test('Cleanstart false', () {
      expect(getConnectFlags(1).cleanStart, isFalse);
    });
    test('Willretain true', () {
      expect(getConnectFlags(32).willRetain, isTrue);
    });
    test('Willretain false', () {
      expect(getConnectFlags(1).willRetain, isFalse);
    });
    test('Willflag true', () {
      expect(getConnectFlags(4).willFlag, isTrue);
    });
    test('Willflag false', () {
      expect(getConnectFlags(1).willFlag, isFalse);
    });
  });

  group('Variable header', () {
    test('Base construction', () {
      final varHeader = MqttVariableHeader();
      varHeader.messageIdentifier = 10;
      varHeader.keepAlive = 3;
      varHeader.topicName = 'Billy';
      varHeader.returnCode = MqttConnectReturnCode.identifierRejected;
      varHeader.connectFlags.cleanStart = true;
      varHeader.connectFlags.willFlag = true;
      final bBuff = typed.Uint8Buffer();
      final byteBuff = MqttByteBuffer(bBuff);
      expect(varHeader.length, 0);
      varHeader.writeTo(byteBuff);
      print(
          'Variable header::Base construction: byte buffer ${byteBuff.buffer.toString()}');
      final varHeader1 = MqttVariableHeader();
      byteBuff.seek(0);
      final writeLength = varHeader.getWriteLength();
      expect(writeLength, 22);
      varHeader1.readFrom(byteBuff);
      expect(varHeader1.returnCode, MqttConnectReturnCode.identifierRejected);
      expect(varHeader1.topicName, 'Billy');
      expect(varHeader1.keepAlive, 3);
      expect(varHeader1.messageIdentifier, 10);
      expect(varHeader1.protocolVersion, 3);
      expect(varHeader1.protocolName, 'MQIsdp');
      expect(varHeader1.connectFlags.willQos, MqttQos.atMostOnce);
      expect(varHeader1.connectFlags.cleanStart, isTrue);
      expect(varHeader1.connectFlags.willFlag, isTrue);
    });
    test('Not enough bytes in string', () {
      final tmp = typed.Uint8Buffer(3);
      tmp[0] = 0;
      tmp[1] = 2;
      tmp[2] = 'm'.codeUnitAt(0);
      final buffer = MqttByteBuffer(tmp);
      var raised = false;
      try {
        MqttByteBuffer.readMqttString(buffer);
      } on Exception catch (exception) {
        expect(exception.toString(),
            'Exception: mqtt_client::ByteBuffer: The buffer did not have enough bytes for the read operation length 3, count 2, position 2, buffer [0, 2, 109]');
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('Long string is fully read', () {
      final tmp = typed.Uint8Buffer(65537);
      tmp.fillRange(2, tmp.length, 'a'.codeUnitAt(0));
      tmp[0] = (tmp.length - 2) >> 8;
      tmp[1] = (tmp.length - 2) & 0xFF;
      final buffer = MqttByteBuffer(tmp);
      final expectedString = String.fromCharCodes(tmp.getRange(2, tmp.length));
      var raised = false;
      try {
        final readString = MqttByteBuffer.readMqttString(buffer);
        expect(readString.length, expectedString.length);
        expect(readString, expectedString);
      } on Exception catch (exception) {
        print(exception.toString());
        raised = true;
      }
      expect(raised, isFalse);
    });
    test('Not enough bytes to form string', () {
      final tmp = typed.Uint8Buffer(1);
      tmp[0] = 0;
      final buffer = MqttByteBuffer(tmp);
      var raised = false;
      try {
        MqttByteBuffer.readMqttString(buffer);
      } on Exception catch (exception) {
        expect(exception.toString(),
            'Exception: mqtt_client::ByteBuffer: The buffer did not have enough bytes for the read operation length 1, count 2, position 0, buffer [0]');
        raised = true;
      }
      expect(raised, isTrue);
    });
  });

  group('Connect', () {
    test('Basic deserialization', () {
      // Our test deserialization message, with the following properties. Note this message is not
      // yet a real MQTT message, because not everything is implemented, but it must be modified
      // and ammeneded as work progresses
      //
      // Message Specs________________
      // <10><15><00><06>MQIsdp<03><02><00><1E><00><07>andy111
      final sampleMessage = <int>[
        0x10,
        0x1B,
        0x00,
        0x06,
        'M'.codeUnitAt(0),
        'Q'.codeUnitAt(0),
        'I'.codeUnitAt(0),
        's'.codeUnitAt(0),
        'd'.codeUnitAt(0),
        'p'.codeUnitAt(0),
        0x03,
        0x2E,
        0x00,
        0x1E,
        0x00,
        0x07,
        'a'.codeUnitAt(0),
        'n'.codeUnitAt(0),
        'd'.codeUnitAt(0),
        'y'.codeUnitAt(0),
        '1'.codeUnitAt(0),
        '1'.codeUnitAt(0),
        '1'.codeUnitAt(0),
        0x00,
        0x01,
        'm'.codeUnitAt(0),
        0x00,
        0x01,
        'a'.codeUnitAt(0)
      ];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print('Connect - Basic deserialization::${baseMessage.toString()}');
      // Check that the message was correctly identified as a connect message.
      expect(baseMessage, const TypeMatcher<MqttConnectMessage>());
      // Validate the message deserialization
      expect(baseMessage.header!.duplicate, isFalse);
      expect(baseMessage.header!.retain, isFalse);
      expect(baseMessage.header!.qos, MqttQos.atMostOnce);
      expect(baseMessage.header!.messageType, MqttMessageType.connect);
      expect(baseMessage.header!.messageSize, 27);
      // Validate the variable header
      final bm = baseMessage as MqttConnectMessage;
      expect(bm.variableHeader!.protocolName, 'MQIsdp');
      expect(bm.variableHeader!.keepAlive, 30);
      expect(bm.variableHeader!.protocolVersion, 3);
      expect(bm.variableHeader!.connectFlags.cleanStart, isTrue);
      expect(bm.variableHeader!.connectFlags.willFlag, isTrue);
      expect(bm.variableHeader!.connectFlags.willRetain, isTrue);
      expect(bm.variableHeader!.connectFlags.willQos, MqttQos.atLeastOnce);
      // Payload tests
      expect(bm.payload.clientIdentifier, 'andy111');
      expect(bm.payload.willTopic, 'm');
      expect(bm.payload.willMessage, 'a');
      bm.authenticateAs('Billy', 'BillyPass');
      expect(bm.payload.username, 'Billy');
      expect(bm.payload.password, 'BillyPass');
      bm.payload.username = 'Billy1';
      bm.payload.password = 'Billy1Pass';
      expect(bm.payload.username, 'Billy1');
      expect(bm.payload.password, 'Billy1Pass');
    });
    test('Payload - invalid client idenfier length', () {
      // Our test deserialization message, with the following properties. Note this message is not
      // yet a real MQTT message, because not everything is implemented, but it must be modified
      // and ammeneded as work progresses
      //
      // Message Specs________________
      // <10><15><00><06>MQIsdp<03><02><00><1E><00><07>andy111andy111andy111andy111
      final sampleMessage = <int>[
        0x10,
        0x15,
        0x00,
        0x06,
        'M'.codeUnitAt(0),
        'Q'.codeUnitAt(0),
        'I'.codeUnitAt(0),
        's'.codeUnitAt(0),
        'd'.codeUnitAt(0),
        'p'.codeUnitAt(0),
        0x03,
        0x02,
        0x00,
        0x1E,
        0x00,
        1053,

        /// greater than 1024
        'a'.codeUnitAt(0),
        'n'.codeUnitAt(0),
        'd'.codeUnitAt(0),
        'y'.codeUnitAt(0),
        '1'.codeUnitAt(0),
        '1'.codeUnitAt(0),
        '1'.codeUnitAt(0),
        'a'.codeUnitAt(0),
        'n'.codeUnitAt(0),
        'd'.codeUnitAt(0),
        'y'.codeUnitAt(0),
        '1'.codeUnitAt(0),
        '1'.codeUnitAt(0),
        '1'.codeUnitAt(0),
        'a'.codeUnitAt(0),
        'n'.codeUnitAt(0),
        'd'.codeUnitAt(0),
        'y'.codeUnitAt(0),
        '1'.codeUnitAt(0),
        '1'.codeUnitAt(0),
        '1'.codeUnitAt(0),
        'a'.codeUnitAt(0),
        'n'.codeUnitAt(0),
        'd'.codeUnitAt(0),
        'y'.codeUnitAt(0),
        '1'.codeUnitAt(0),
        '1'.codeUnitAt(0),
        '1'.codeUnitAt(0)
      ];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      var raised = false;
      try {
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print(baseMessage.toString());
      } on Exception {
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('Basic serialization', () {
      final msg =
          MqttConnectMessage().withClientIdentifier('mark').startClean();
      print('Connect - Basic serialization::${msg.toString()}');
      final mb = MessageSerializationHelper.getMessageBytes(msg);
      expect(mb[0], 0x10);
      // VH will = 12, Msg = 6
      expect(mb[1], 0x12);
    });
    test('With will set', () {
      final msg = MqttConnectMessage()
          .withProtocolName('MQIsdp')
          .withProtocolVersion(3)
          .withClientIdentifier('mark')
          .startClean()
          .will()
          .withWillQos(MqttQos.atLeastOnce)
          .withWillRetain()
          .withWillTopic('willTopic')
          .withWillMessage('willMessage');
      print('Connect - With will set::${msg.toString()}');
      final mb = MessageSerializationHelper.getMessageBytes(msg);
      expect(mb[0], 0x10);
      // VH will = 12, Msg = 6
      expect(mb[1], 0x2A);
    });
  });

  group('Connect Ack', () {
    test('Deserialisation - Connection accepted', () {
      // Our test deserialization message, with the following properties. Note this message is not
      // yet a real MQTT message, because not everything is implemented, but it must be modified
      // and amended as work progresses
      //
      // Message Specs________________
      // <20><02><00><00>
      final sampleMessage = typed.Uint8Buffer(4);
      sampleMessage[0] = 0x20;
      sampleMessage[1] = 0x02;
      sampleMessage[2] = 0x0;
      sampleMessage[3] = 0x0;
      final byteBuffer = MqttByteBuffer(sampleMessage);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print('Connect Ack - Connection accepted::${baseMessage.toString()}');
      // Check that the message was correctly identified as a connect ack message.
      expect(baseMessage, const TypeMatcher<MqttConnectAckMessage>());
      final message = baseMessage as MqttConnectAckMessage;
      // Validate the message deserialization
      expect(
        message.header!.duplicate,
        false,
      );
      expect(
        message.header!.retain,
        false,
      );
      expect(message.header!.qos, MqttQos.atMostOnce);
      expect(message.header!.messageType, MqttMessageType.connectAck);
      expect(message.header!.messageSize, 2);
      // Validate the variable header
      expect(message.variableHeader.returnCode,
          MqttConnectReturnCode.connectionAccepted);
    });
    test('Deserialisation - Unacceptable protocol version', () {
      // Our test deserialization message, with the following properties. Note this message is not
      // yet a real MQTT message, because not everything is implemented, but it must be modified
      // and amended as work progresses
      //
      // Message Specs________________
      // <20><02><00><00>
      final sampleMessage = typed.Uint8Buffer(4);
      sampleMessage[0] = 0x20;
      sampleMessage[1] = 0x02;
      sampleMessage[2] = 0x0;
      sampleMessage[3] = 0x1;
      final byteBuffer = MqttByteBuffer(sampleMessage);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print(
          'Connect Ack - Unacceptable protocol version::${baseMessage.toString()}');
      // Check that the message was correctly identified as a connect ack message.
      expect(baseMessage, const TypeMatcher<MqttConnectAckMessage>());
      final message = baseMessage as MqttConnectAckMessage;
      // Validate the message deserialization
      expect(
        message.header!.duplicate,
        false,
      );
      expect(
        message.header!.retain,
        false,
      );
      expect(message.header!.qos, MqttQos.atMostOnce);
      expect(message.header!.messageType, MqttMessageType.connectAck);
      expect(message.header!.messageSize, 2);
      // Validate the variable header
      expect(message.variableHeader.returnCode,
          MqttConnectReturnCode.unacceptedProtocolVersion);
    });
    test('Deserialisation - Identifier rejected', () {
      // Our test deserialization message, with the following properties. Note this message is not
      // yet a real MQTT message, because not everything is implemented, but it must be modified
      // and amended as work progresses
      //
      // Message Specs________________
      // <20><02><00><00>
      final sampleMessage = typed.Uint8Buffer(4);
      sampleMessage[0] = 0x20;
      sampleMessage[1] = 0x02;
      sampleMessage[2] = 0x0;
      sampleMessage[3] = 0x2;
      final byteBuffer = MqttByteBuffer(sampleMessage);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print('Connect Ack - Identifier rejected::${baseMessage.toString()}');
      // Check that the message was correctly identified as a connect ack message.
      expect(baseMessage, const TypeMatcher<MqttConnectAckMessage>());
      final message = baseMessage as MqttConnectAckMessage;
      // Validate the message deserialization
      expect(
        message.header!.duplicate,
        false,
      );
      expect(
        message.header!.retain,
        false,
      );
      expect(message.header!.qos, MqttQos.atMostOnce);
      expect(message.header!.messageType, MqttMessageType.connectAck);
      expect(message.header!.messageSize, 2);
      // Validate the variable header
      expect(message.variableHeader.returnCode,
          MqttConnectReturnCode.identifierRejected);
    });
    test('Deserialisation - Broker unavailable', () {
      // Our test deserialization message, with the following properties. Note this message is not
      // yet a real MQTT message, because not everything is implemented, but it must be modified
      // and amended as work progresses
      //
      // Message Specs________________
      // <20><02><00><00>
      final sampleMessage = typed.Uint8Buffer(4);
      sampleMessage[0] = 0x20;
      sampleMessage[1] = 0x02;
      sampleMessage[2] = 0x0;
      sampleMessage[3] = 0x3;
      final byteBuffer = MqttByteBuffer(sampleMessage);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print('Connect Ack - Broker unavailable::${baseMessage.toString()}');
      // Check that the message was correctly identified as a connect ack message.
      expect(baseMessage, const TypeMatcher<MqttConnectAckMessage>());
      final message = baseMessage as MqttConnectAckMessage;
      // Validate the message deserialization
      expect(
        message.header!.duplicate,
        false,
      );
      expect(
        message.header!.retain,
        false,
      );
      expect(message.header!.qos, MqttQos.atMostOnce);
      expect(message.header!.messageType, MqttMessageType.connectAck);
      expect(message.header!.messageSize, 2);
      // Validate the variable header
      expect(message.variableHeader.returnCode,
          MqttConnectReturnCode.brokerUnavailable);
    });
  });
  test('Serialisation - Connection accepted', () {
    final expected = typed.Uint8Buffer(4);
    expected[0] = 0x20;
    expected[1] = 0x02;
    expected[2] = 0x0;
    expected[3] = 0x0;
    final msg = MqttConnectAckMessage()
        .withReturnCode(MqttConnectReturnCode.connectionAccepted);
    print('Connect Ack - Connection accepted::${msg.toString()}');
    final actual = MessageSerializationHelper.getMessageBytes(msg);
    expect(actual.length, expected.length);
    expect(actual[0], expected[0]); // msg type of header
    expect(actual[1], expected[1]); // remaining length
    expect(actual[2], expected[2]); // connect ack - compression? always empty
    expect(actual[3], expected[3]); // return code.
  });
  test('Serialisation - Unacceptable protocol version', () {
    final expected = typed.Uint8Buffer(4);
    expected[0] = 0x20;
    expected[1] = 0x02;
    expected[2] = 0x0;
    expected[3] = 0x1;
    final msg = MqttConnectAckMessage()
        .withReturnCode(MqttConnectReturnCode.unacceptedProtocolVersion);
    print('Connect Ack - Unacceptable protocol version::${msg.toString()}');
    final actual = MessageSerializationHelper.getMessageBytes(msg);
    expect(actual.length, expected.length);
    expect(actual[0], expected[0]); // msg type of header
    expect(actual[1], expected[1]); // remaining length
    expect(actual[2], expected[2]); // connect ack - compression? always empty
    expect(actual[3], expected[3]); // return code.
  });
  test('Serialisation - Identifier rejected', () {
    final expected = typed.Uint8Buffer(4);
    expected[0] = 0x20;
    expected[1] = 0x02;
    expected[2] = 0x0;
    expected[3] = 0x2;
    final msg = MqttConnectAckMessage()
        .withReturnCode(MqttConnectReturnCode.identifierRejected);
    print('Connect Ack - Identifier rejected::${msg.toString()}');
    final actual = MessageSerializationHelper.getMessageBytes(msg);
    expect(actual.length, expected.length);
    expect(actual[0], expected[0]); // msg type of header
    expect(actual[1], expected[1]); // remaining length
    expect(actual[2], expected[2]); // connect ack - compression? always empty
    expect(actual[3], expected[3]); // return code.
  });
  test('Serialisation - Broker unavailable', () {
    final expected = typed.Uint8Buffer(4);
    expected[0] = 0x20;
    expected[1] = 0x02;
    expected[2] = 0x0;
    expected[3] = 0x3;
    final msg = MqttConnectAckMessage()
        .withReturnCode(MqttConnectReturnCode.brokerUnavailable);
    print('Connect Ack - Broker unavailable::${msg.toString()}');
    final actual = MessageSerializationHelper.getMessageBytes(msg);
    expect(actual.length, expected.length);
    expect(actual[0], expected[0]); // msg type of header
    expect(actual[1], expected[1]); // remaining length
    expect(actual[2], expected[2]); // connect ack - compression? always empty
    expect(actual[3], expected[3]); // return code.
  });

  group('Disconnect', () {
    test('Deserialisation', () {
      final sampleMessage = typed.Uint8Buffer(2);
      sampleMessage[0] = 0xE0;
      sampleMessage[1] = 0x0;
      final byteBuffer = MqttByteBuffer(sampleMessage);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print('Disconnect  - Deserialisation::${baseMessage.toString()}');
      // Check that the message was correctly identified as a disconnect message.
      expect(baseMessage, const TypeMatcher<MqttDisconnectMessage>());
    });
    test('Serialisation', () {
      final expected = typed.Uint8Buffer(2);
      expected[0] = 0xE0;
      expected[1] = 0x00;
      final msg = MqttDisconnectMessage();
      print('Disconnect - Serialisation::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]);
      expect(actual[1], expected[1]);
    });
  });

  group('Ping Request', () {
    test('Deserialisation', () {
      final sampleMessage = typed.Uint8Buffer(2);
      sampleMessage[0] = 0xC0;
      sampleMessage[1] = 0x0;
      final byteBuffer = MqttByteBuffer(sampleMessage);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print('Ping Request  - Deserialisation::${baseMessage.toString()}');
      // Check that the message was correctly identified as a ping request message.
      expect(baseMessage, const TypeMatcher<MqttPingRequestMessage>());
    });
    test('Serialisation', () {
      final expected = typed.Uint8Buffer(2);
      expected[0] = 0xC0;
      expected[1] = 0x00;
      final msg = MqttPingRequestMessage();
      print('Ping Request - Serialisation::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]);
      expect(actual[1], expected[1]);
    });
  });

  group('Ping Response', () {
    test('Deserialisation', () {
      final sampleMessage = typed.Uint8Buffer(2);
      sampleMessage[0] = 0xD0;
      sampleMessage[1] = 0x00;
      final byteBuffer = MqttByteBuffer(sampleMessage);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print('Ping Response  - Deserialisation::${baseMessage.toString()}');
      // Check that the message was correctly identified as a ping response message.
      expect(baseMessage, const TypeMatcher<MqttPingResponseMessage>());
    });
    test('Serialisation', () {
      final expected = typed.Uint8Buffer(2);
      expected[0] = 0xD0;
      expected[1] = 0x00;
      final msg = MqttPingResponseMessage();
      print('Ping Response - Serialisation::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]);
      expect(actual[1], expected[1]);
    });
  });

  group('Publish', () {
    test('Deserialisation - Valid payload', () {
      // Tests basic message deserialization from a raw byte array.
      // Message Specs________________
      // <30><0C><00><04>fredhello!
      final sampleMessage = <int>[
        0x30,
        0x0C,
        0x00,
        0x04,
        'f'.codeUnitAt(0),
        'r'.codeUnitAt(0),
        'e'.codeUnitAt(0),
        'd'.codeUnitAt(0),
        // message payload is here
        'h'.codeUnitAt(0),
        'e'.codeUnitAt(0),
        'l'.codeUnitAt(0),
        'l'.codeUnitAt(0),
        'o'.codeUnitAt(0),
        '!'.codeUnitAt(0)
      ];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print('Publish - Valid payload::${baseMessage.toString()}');
      // Check that the message was correctly identified as a publish message.
      expect(baseMessage, const TypeMatcher<MqttPublishMessage>());
      // Validate the message deserialization
      expect(baseMessage.header!.duplicate, isFalse);
      expect(baseMessage.header!.retain, isFalse);
      expect(baseMessage.header!.qos, MqttQos.atMostOnce);
      expect(baseMessage.header!.messageType, MqttMessageType.publish);
      expect(baseMessage.header!.messageSize, 12);
      final pm = baseMessage as MqttPublishMessage;
      // Check the payload
      expect(pm.payload.message[0], 'h'.codeUnitAt(0));
      expect(pm.payload.message[1], 'e'.codeUnitAt(0));
      expect(pm.payload.message[2], 'l'.codeUnitAt(0));
      expect(pm.payload.message[3], 'l'.codeUnitAt(0));
      expect(pm.payload.message[4], 'o'.codeUnitAt(0));
      expect(pm.payload.message[5], '!'.codeUnitAt(0));
    });
    test('Deserialisation - Valid payload V311', () {
      // Tests basic message deserialization from a raw byte array.
      // Message Specs________________
      // <30><0C><00><04>fredhello!
      final sampleMessage = <int>[
        0x30,
        0x0C,
        0x00,
        0x04,
        'f'.codeUnitAt(0),
        'r'.codeUnitAt(0),
        'e'.codeUnitAt(0),
        'd'.codeUnitAt(0),
        // message payload is here
        'h'.codeUnitAt(0),
        'e'.codeUnitAt(0),
        'l'.codeUnitAt(0),
        'l'.codeUnitAt(0),
        'o'.codeUnitAt(0),
        '!'.codeUnitAt(0)
      ];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      Protocol.version = MqttClientConstants.mqttV311ProtocolVersion;
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print('Publish - Valid payload::${baseMessage.toString()}');
      // Check that the message was correctly identified as a publish message.
      expect(baseMessage, const TypeMatcher<MqttPublishMessage>());
      // Validate the message deserialization
      expect(baseMessage.header!.duplicate, isFalse);
      expect(baseMessage.header!.retain, isFalse);
      expect(baseMessage.header!.qos, MqttQos.atMostOnce);
      expect(baseMessage.header!.messageType, MqttMessageType.publish);
      expect(baseMessage.header!.messageSize, 12);
      final pm = baseMessage as MqttPublishMessage;
      // Check the payload
      expect(pm.payload.message[0], 'h'.codeUnitAt(0));
      expect(pm.payload.message[1], 'e'.codeUnitAt(0));
      expect(pm.payload.message[2], 'l'.codeUnitAt(0));
      expect(pm.payload.message[3], 'l'.codeUnitAt(0));
      expect(pm.payload.message[4], 'o'.codeUnitAt(0));
      expect(pm.payload.message[5], '!'.codeUnitAt(0));
    });
    test('Deserialisation - payload too short', () {
      final sampleMessage = <int>[
        0x30,
        0x0C,
        0x00,
        0x04,
        'f'.codeUnitAt(0),
        'r'.codeUnitAt(0),
        'e'.codeUnitAt(0),
        'd'.codeUnitAt(0),
        // message payload is here
        'h'.codeUnitAt(0),
        'e'.codeUnitAt(0),
        'l'.codeUnitAt(0),
        'l'.codeUnitAt(0),
        'o'.codeUnitAt(0)
      ];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      var raised = false;
      try {
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print(baseMessage.toString());
      } on Exception {
        raised = true;
      }
      expect(raised, isTrue);
    });
    test('Serialisation - Qos Level 2 Exactly Once', () {
      final expected = <int>[
        0x34,
        0x0E,
        0x00,
        0x04,
        'f'.codeUnitAt(0),
        'r'.codeUnitAt(0),
        'e'.codeUnitAt(0),
        'd'.codeUnitAt(0),
        0x00,
        0x0A,
        // message payload is here
        'h'.codeUnitAt(0),
        'e'.codeUnitAt(0),
        'l'.codeUnitAt(0),
        'l'.codeUnitAt(0),
        'o'.codeUnitAt(0),
        '!'.codeUnitAt(0)
      ];
      final payload = typed.Uint8Buffer(6);
      payload[0] = 'h'.codeUnitAt(0);
      payload[1] = 'e'.codeUnitAt(0);
      payload[2] = 'l'.codeUnitAt(0);
      payload[3] = 'l'.codeUnitAt(0);
      payload[4] = 'o'.codeUnitAt(0);
      payload[5] = '!'.codeUnitAt(0);
      final msg = MqttPublishMessage()
          .withQos(MqttQos.exactlyOnce)
          .withMessageIdentifier(10)
          .toTopic('fred')
          .publishData(payload);
      print('Publish - Qos Level 2 Exactly Once::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]); // msg type of header + other bits
      expect(actual[1], expected[1]); // remaining length
      expect(actual[2], expected[2]); // first topic length byte
      expect(actual[3], expected[3]); // second topic length byte
      expect(actual[4], expected[4]); // f
      expect(actual[5], expected[5]); // r
      expect(actual[6], expected[6]); // e
      expect(actual[7], expected[7]); // d
      expect(actual[8], expected[8]); // h
      expect(actual[9], expected[9]); // e
      expect(actual[10], expected[10]); // l
      expect(actual[11], expected[11]); // l
      expect(actual[12], expected[12]); // o
      expect(actual[13], expected[13]); // !
    });
    test('Serialisation - Topic has special characters', () {
      final expected = <int>[
        0x34,
        0x0E,
        0x00,
        0x04,
        'f'.codeUnitAt(0),
        'r'.codeUnitAt(0),
        'e'.codeUnitAt(0),
        'd'.codeUnitAt(0),
        0x00,
        0x0A,
        // message payload is here
        'h'.codeUnitAt(0),
        'e'.codeUnitAt(0),
        'l'.codeUnitAt(0),
        'l'.codeUnitAt(0),
        'o'.codeUnitAt(0),
        '!'.codeUnitAt(0)
      ];
      final payload = typed.Uint8Buffer(6);
      payload[0] = 'h'.codeUnitAt(0);
      payload[1] = 'e'.codeUnitAt(0);
      payload[2] = 'l'.codeUnitAt(0);
      payload[3] = 'l'.codeUnitAt(0);
      payload[4] = 'o'.codeUnitAt(0);
      payload[5] = '!'.codeUnitAt(0);
      Protocol.version = MqttClientConstants.mqttV311ProtocolVersion;
      final msg = MqttPublishMessage()
          .withQos(MqttQos.exactlyOnce)
          .withMessageIdentifier(10)
          .toTopic(
              '/hfp/v1/journey/ongoing/bus/0012/01314/2550/2/Itäkeskus(M)/19:16/1454121/3/60;25/20/14/83')
          .publishData(payload);
      print('Publish - Qos Level 2 Exactly Once::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, 102);
      expect(actual[0], expected[0]); // msg type of header + other bits
      expect(actual[1], 100); // remaining length
      expect(actual[2], expected[2]); // first topic length byte
      expect(actual[3], 90); // second topic length byte
      expect(actual[4], 47);
      expect(actual[5], 104);
      expect(actual[6], 102);
      expect(actual[7], 112);
    });
    test('Serialisation - Qos Level 0 No MID', () {
      final expected = <int>[
        0x30,
        0x0C,
        0x00,
        0x04,
        'f'.codeUnitAt(0),
        'r'.codeUnitAt(0),
        'e'.codeUnitAt(0),
        'd'.codeUnitAt(0),
        // message payload is here
        'h'.codeUnitAt(0),
        'e'.codeUnitAt(0),
        'l'.codeUnitAt(0),
        'l'.codeUnitAt(0),
        'o'.codeUnitAt(0),
        '!'.codeUnitAt(0)
      ];
      final payload = typed.Uint8Buffer(6);
      payload[0] = 'h'.codeUnitAt(0);
      payload[1] = 'e'.codeUnitAt(0);
      payload[2] = 'l'.codeUnitAt(0);
      payload[3] = 'l'.codeUnitAt(0);
      payload[4] = 'o'.codeUnitAt(0);
      payload[5] = '!'.codeUnitAt(0);
      final msg = MqttPublishMessage().toTopic('fred').publishData(payload);
      print('Publish - Qos Level 0 No MID::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]); // msg type of header + other bits
      expect(actual[1], expected[1]); // remaining length
      expect(actual[2], expected[2]); // first topic length byte
      expect(actual[3], expected[3]); // second topic length byte
      expect(actual[4], expected[4]); // f
      expect(actual[5], expected[5]); // r
      expect(actual[6], expected[6]); // e
      expect(actual[7], expected[7]); // d
      expect(actual[8], expected[8]); // h
      expect(actual[9], expected[9]); // e
      expect(actual[10], expected[10]); // l
      expect(actual[11], expected[11]); // l
      expect(actual[12], expected[12]); // o
      expect(actual[13], expected[13]); // !
    });
    test('Serialisation - With non-default Qos', () {
      final msg = MqttPublishMessage()
          .toTopic('mark')
          .withQos(MqttQos.atLeastOnce)
          .withMessageIdentifier(4)
          .publishData(typed.Uint8Buffer(9));
      final msgBytes = MessageSerializationHelper.getMessageBytes(msg);
      expect(msgBytes.length, 19);
    });
    test('Clear publish data', () {
      final data = typed.Uint8Buffer(2);
      data[0] = 0;
      data[1] = 1;
      final msg = MqttPublishMessage().publishData(data);
      expect(msg.payload.message.length, 2);
      msg.clearPublishData();
      expect(msg.payload.message.length, 0);
    });
  });

  group('Publish Ack', () {
    test('Deserialisation - Valid payload', () {
      // Tests basic message deserialization from a raw byte array.
      // Message Specs________________
      // <30><0C><00><04>fredhello!
      final sampleMessage = <int>[
        0x40,
        0x02,
        0x00,
        0x04,
      ];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print('Publish Ack - Valid payload::${baseMessage.toString()}');
      // Check that the message was correctly identified as a publish ack message.
      expect(baseMessage, const TypeMatcher<MqttPublishAckMessage>());
      // Validate the message deserialization
      expect(baseMessage.header!.messageType, MqttMessageType.publishAck);
      expect(baseMessage.header!.messageSize, 2);
      final bm = baseMessage as MqttPublishAckMessage;
      expect(bm.variableHeader.messageIdentifier, 4);
    });
    test('Serialisation - Valid payload', () {
      // Publish ack msg with message identifier 4
      final expected = typed.Uint8Buffer(4);
      expected[0] = 0x40;
      expected[1] = 0x02;
      expected[2] = 0x0;
      expected[3] = 0x4;
      final msg = MqttPublishAckMessage().withMessageIdentifier(4);
      print('Publish Ack - Valid payload::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]); // msg type of header + other bits
      expect(actual[1], expected[1]); // remaining length
      expect(actual[2], expected[2]); // first topic length byte
      expect(actual[3], expected[3]); // second topic length byte
    });
  });

  group('Publish Complete', () {
    test('Deserialisation - Valid payload', () {
      // Message Specs________________
      // <40><02><00><04> (Pub complete for Message ID 4)
      final sampleMessage = <int>[
        0x70,
        0x02,
        0x00,
        0x04,
      ];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print('Publish Complete - Valid payload::${baseMessage.toString()}');
      // Check that the message was correctly identified as a publish complete message.
      expect(baseMessage, const TypeMatcher<MqttPublishCompleteMessage>());
      // Validate the message deserialization
      expect(baseMessage.header!.messageType, MqttMessageType.publishComplete);
      expect(baseMessage.header!.messageSize, 2);
      final bm = baseMessage as MqttPublishCompleteMessage;
      expect(bm.variableHeader.messageIdentifier, 4);
    });
    test('Serialisation - Valid payload', () {
      // Publish complete msg with message identifier 4
      final expected = typed.Uint8Buffer(4);
      expected[0] = 0x70;
      expected[1] = 0x02;
      expected[2] = 0x0;
      expected[3] = 0x4;
      final msg = MqttPublishCompleteMessage().withMessageIdentifier(4);
      print('Publish Complete - Valid payload::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]); // msg type of header + other bits
      expect(actual[1], expected[1]); // remaining length
      expect(actual[2], expected[2]); // first topic length byte
      expect(actual[3], expected[3]); // second topic length byte
    });
  });

  group('Publish Received', () {
    test('Deserialisation - Valid payload', () {
      // Message Specs________________
      // <40><02><00><04> (Pub Received for Message ID 4)
      final sampleMessage = <int>[
        0x50,
        0x02,
        0x00,
        0x04,
      ];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print('Publish Received - Valid payload::${baseMessage.toString()}');
      // Check that the message was correctly identified as a publish received message.
      expect(baseMessage, const TypeMatcher<MqttPublishReceivedMessage>());
      // Validate the message deserialization
      expect(baseMessage.header!.messageType, MqttMessageType.publishReceived);
      expect(baseMessage.header!.messageSize, 2);
      final bm = baseMessage as MqttPublishReceivedMessage;
      expect(bm.variableHeader.messageIdentifier, 4);
    });
    test('Serialisation - Valid payload', () {
      // Publish complete msg with message identifier 4
      final expected = typed.Uint8Buffer(4);
      expected[0] = 0x50;
      expected[1] = 0x02;
      expected[2] = 0x0;
      expected[3] = 0x4;
      final msg = MqttPublishReceivedMessage().withMessageIdentifier(4);
      print('Publish Received - Valid payload::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]); // msg type of header + other bits
      expect(actual[1], expected[1]); // remaining length
      expect(actual[2], expected[2]); // first topic length byte
      expect(actual[3], expected[3]); // second topic length byte
    });
  });

  group('Publish Release', () {
    test('Deserialisation - Valid payload', () {
      // Message Specs________________
      // <40><02><00><04> (Pub Release for Message ID 4)
      final sampleMessage = <int>[
        0x60,
        0x02,
        0x00,
        0x04,
      ];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print('Publish Release - Valid payload::${baseMessage.toString()}');
      // Check that the message was correctly identified as a publish release message.
      expect(baseMessage, const TypeMatcher<MqttPublishReleaseMessage>());
      // Validate the message deserialization
      expect(baseMessage.header!.messageType, MqttMessageType.publishRelease);
      expect(baseMessage.header!.messageSize, 2);
      final bm = baseMessage as MqttPublishReleaseMessage;
      expect(bm.variableHeader.messageIdentifier, 4);
    });
    test('Serialisation - Valid payload', () {
      // Publish complete msg with message identifier 4
      final expected = typed.Uint8Buffer(4);
      expected[0] = 0x62;
      expected[1] = 0x02;
      expected[2] = 0x0;
      expected[3] = 0x4;
      final msg = MqttPublishReleaseMessage().withMessageIdentifier(4);
      print('Publish Release - Valid payload::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]); // msg type of header + other bits
      expect(actual[1], expected[1]); // remaining length
      expect(actual[2], expected[2]); // first topic length byte
      expect(actual[3], expected[3]); // second topic length byte
    });
  });

  group('Subscribe', () {
    test('Deserialisation - Single topic', () {
      // Message Specs________________
      // <82><09><00><02><00><04>fred<00> (subscribe to topic fred at qos 0)
      final sampleMessage = <int>[
        0x82,
        0x09,
        0x00,
        0x02,
        0x00,
        0x04,
        'f'.codeUnitAt(0),
        'r'.codeUnitAt(0),
        'e'.codeUnitAt(0),
        'd'.codeUnitAt(0),
        0x00
      ];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print('Subscribe - Single topic::${baseMessage.toString()}');
      // Check that the message was correctly identified as a subscribe message.
      expect(baseMessage, const TypeMatcher<MqttSubscribeMessage>());
      final bm = baseMessage as MqttSubscribeMessage;
      expect(bm.payload.subscriptions.length, 1);
      expect(bm.payload.subscriptions.containsKey('fred'), isTrue);
      expect(bm.payload.subscriptions['fred'], MqttQos.atMostOnce);
    });
    test('Deserialisation - Multi topic', () {
      // Message Specs________________
      // <82><10><00><02><00><04>fred<00> (subscribe to topic fred at qos 0)
      final sampleMessage = <int>[
        0x82,
        0x10,
        0x00,
        0x02,
        0x00,
        0x04,
        'f'.codeUnitAt(0),
        'r'.codeUnitAt(0),
        'e'.codeUnitAt(0),
        'd'.codeUnitAt(0),
        0x00,
        0x00,
        0x04,
        'm'.codeUnitAt(0),
        'a'.codeUnitAt(0),
        'r'.codeUnitAt(0),
        'k'.codeUnitAt(0),
        0x00
      ];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print('Subscribe - Multi topic::${baseMessage.toString()}');
      // Check that the message was correctly identified as a subscribe message.
      expect(baseMessage, const TypeMatcher<MqttSubscribeMessage>());
      final bm = baseMessage as MqttSubscribeMessage;
      expect(bm.payload.subscriptions.length, 2);
      expect(bm.payload.subscriptions.containsKey('fred'), isTrue);
      expect(bm.payload.subscriptions['fred'], MqttQos.atMostOnce);
      expect(bm.payload.subscriptions.containsKey('mark'), isTrue);
      expect(bm.payload.subscriptions['mark'], MqttQos.atMostOnce);
    });
    test('Deserialisation - Single topic at least once Qos', () {
      // Message Specs________________
      // <82><09><00><02><00><04>fred<00> (subscribe to topic fred at qos 0)
      final sampleMessage = <int>[
        0x82,
        0x09,
        0x00,
        0x02,
        0x00,
        0x04,
        'f'.codeUnitAt(0),
        'r'.codeUnitAt(0),
        'e'.codeUnitAt(0),
        'd'.codeUnitAt(0),
        0x01
      ];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print(
          'Subscribe - Single topic at least once Qos::${baseMessage.toString()}');
      // Check that the message was correctly identified as a subscribe message.
      expect(baseMessage, const TypeMatcher<MqttSubscribeMessage>());
      final bm = baseMessage as MqttSubscribeMessage;
      expect(bm.payload.subscriptions.length, 1);
      expect(bm.payload.subscriptions.containsKey('fred'), isTrue);
      expect(bm.payload.subscriptions['fred'], MqttQos.atLeastOnce);
    });
    test('Deserialisation - Multi topic at least once Qos', () {
      // Message Specs________________
      // <82><10><00><02><00><04>fred<00> (subscribe to topic fred at qos 0)
      final sampleMessage = <int>[
        0x82,
        0x10,
        0x00,
        0x02,
        0x00,
        0x04,
        'f'.codeUnitAt(0),
        'r'.codeUnitAt(0),
        'e'.codeUnitAt(0),
        'd'.codeUnitAt(0),
        0x01,
        0x00,
        0x04,
        'm'.codeUnitAt(0),
        'a'.codeUnitAt(0),
        'r'.codeUnitAt(0),
        'k'.codeUnitAt(0),
        0x01
      ];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print(
          'Subscribe - Multi topic at least once Qos::${baseMessage.toString()}');
      // Check that the message was correctly identified as a subscribe message.
      expect(baseMessage, const TypeMatcher<MqttSubscribeMessage>());
      final bm = baseMessage as MqttSubscribeMessage;
      expect(bm.payload.subscriptions.length, 2);
      expect(bm.payload.subscriptions.containsKey('fred'), isTrue);
      expect(bm.payload.subscriptions['fred'], MqttQos.atLeastOnce);
      expect(bm.payload.subscriptions.containsKey('mark'), isTrue);
      expect(bm.payload.subscriptions['mark'], MqttQos.atLeastOnce);
    });
    test('Deserialisation - Single topic exactly once Qos', () {
      // Message Specs________________
      // <82><09><00><02><00><04>fred<00> (subscribe to topic fred at qos 0)
      final sampleMessage = <int>[
        0x82,
        0x09,
        0x00,
        0x02,
        0x00,
        0x04,
        'f'.codeUnitAt(0),
        'r'.codeUnitAt(0),
        'e'.codeUnitAt(0),
        'd'.codeUnitAt(0),
        0x02
      ];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print(
          'Subscribe - Single topic exactly once Qos::${baseMessage.toString()}');
      // Check that the message was correctly identified as a subscribe message.
      expect(baseMessage, const TypeMatcher<MqttSubscribeMessage>());
      final bm = baseMessage as MqttSubscribeMessage;
      expect(bm.payload.subscriptions.length, 1);
      expect(bm.payload.subscriptions.containsKey('fred'), isTrue);
      expect(bm.payload.subscriptions['fred'], MqttQos.exactlyOnce);
    });
    test('Deserialisation - Multi topic exactly once Qos', () {
      // Message Specs________________
      // <82><10><00><02><00><04>fred<00> (subscribe to topic fred at qos 0)
      final sampleMessage = <int>[
        0x82,
        0x10,
        0x00,
        0x02,
        0x00,
        0x04,
        'f'.codeUnitAt(0),
        'r'.codeUnitAt(0),
        'e'.codeUnitAt(0),
        'd'.codeUnitAt(0),
        0x02,
        0x00,
        0x04,
        'm'.codeUnitAt(0),
        'a'.codeUnitAt(0),
        'r'.codeUnitAt(0),
        'k'.codeUnitAt(0),
        0x02
      ];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print(
          'Subscribe - Multi topic exactly once Qos::${baseMessage.toString()}');
      // Check that the message was correctly identified as a subscribe message.
      expect(baseMessage, const TypeMatcher<MqttSubscribeMessage>());
      final bm = baseMessage as MqttSubscribeMessage;
      expect(bm.payload.subscriptions.length, 2);
      expect(bm.payload.subscriptions.containsKey('fred'), isTrue);
      expect(bm.payload.subscriptions['fred'], MqttQos.exactlyOnce);
      expect(bm.payload.subscriptions.containsKey('mark'), isTrue);
      expect(bm.payload.subscriptions['mark'], MqttQos.exactlyOnce);
    });
    test('Serialisation - Single topic', () {
      final expected = typed.Uint8Buffer(11);
      expected[0] = 0x8A;
      expected[1] = 0x09;
      expected[2] = 0x00;
      expected[3] = 0x02;
      expected[4] = 0x00;
      expected[5] = 0x04;
      expected[6] = 'f'.codeUnitAt(0);
      expected[7] = 'r'.codeUnitAt(0);
      expected[8] = 'e'.codeUnitAt(0);
      expected[9] = 'd'.codeUnitAt(0);
      expected[10] = 0x01;
      final msg = MqttSubscribeMessage()
          .toTopic('fred')
          .atQos(MqttQos.atLeastOnce)
          .withMessageIdentifier(2)
          .expectAcknowledgement()
          .isDuplicate();
      print('Subscribe - Single topic::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]); // msg type of header + other bits
      expect(actual[1], expected[1]); // remaining length
      expect(actual[2], expected[2]); // Start of VH: MsgID Byte1
      expect(actual[3], expected[3]); // MsgID Byte 2
      expect(actual[4], expected[4]); // Topic Length B1
      expect(actual[5], expected[5]); // Topic Length B2
      expect(actual[6], expected[6]); // f
      expect(actual[7], expected[7]); // r
      expect(actual[8], expected[8]); // e
      expect(actual[9], expected[9]); // d
    });
    test('Serialisation - multi topic', () {
      final expected = typed.Uint8Buffer(18);
      expected[0] = 0x82;
      expected[1] = 0x10;
      expected[2] = 0x00;
      expected[3] = 0x03;
      expected[4] = 0x00;
      expected[5] = 0x04;
      expected[6] = 'f'.codeUnitAt(0);
      expected[7] = 'r'.codeUnitAt(0);
      expected[8] = 'e'.codeUnitAt(0);
      expected[9] = 'd'.codeUnitAt(0);
      expected[10] = 0x01;
      expected[11] = 0x00;
      expected[12] = 0x04;
      expected[13] = 'm'.codeUnitAt(0);
      expected[14] = 'a'.codeUnitAt(0);
      expected[15] = 'r'.codeUnitAt(0);
      expected[16] = 'k'.codeUnitAt(0);
      expected[17] = 0x02;
      final msg = MqttSubscribeMessage()
          .toTopic('fred')
          .atQos(MqttQos.atLeastOnce)
          .toTopic('mark')
          .atQos(MqttQos.exactlyOnce)
          .withMessageIdentifier(3)
          .expectAcknowledgement();
      print('Subscribe - multi topic::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]); // msg type of header + other bits
      expect(actual[1], expected[1]); // remaining length
      expect(actual[2], expected[2]); // Start of VH: MsgID Byte1
      expect(actual[3], expected[3]); // MsgID Byte 2
      expect(actual[4], expected[4]); // Topic Length B1
      expect(actual[5], expected[5]); // Topic Length B2
      expect(actual[6], expected[6]); // f
      expect(actual[7], expected[7]); // r
      expect(actual[8], expected[8]); // e
      expect(actual[9], expected[9]); // d
      expect(actual[10], expected[10]); // Qos (LeastOnce)
      expect(actual[11], expected[11]); // Topic Length B1
      expect(actual[12], expected[12]); // Topic Length B2
      expect(actual[13], expected[13]); // m
      expect(actual[14], expected[14]); // a
      expect(actual[15], expected[15]); // r
      expect(actual[16], expected[16]); // k
      expect(actual[17], expected[17]); // Qos (ExactlyOnce)
    });
    test('Add subscription over existing subscription', () {
      final msg = MqttSubscribeMessage();
      msg.payload.addSubscription('A/Topic', MqttQos.atMostOnce);
      msg.payload.addSubscription('A/Topic', MqttQos.atLeastOnce);
      expect(msg.payload.subscriptions['A/Topic'], MqttQos.atLeastOnce);
    });
    test('Clear subscription', () {
      final msg = MqttSubscribeMessage();
      msg.payload.addSubscription('A/Topic', MqttQos.atMostOnce);
      msg.payload.clearSubscriptions();
      expect(msg.payload.subscriptions.length, 0);
    });
  });

  group('Subscribe Ack', () {
    test('Deserialisation - Single Qos at most once', () {
      // Message Specs________________
      // <90><03><00><02><00>
      final sampleMessage = <int>[0x90, 0x03, 0x00, 0x02, 0x00];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print(
          'Subscribe Ack - Single Qos at most once::${baseMessage.toString()}');
      // Check that the message was correctly identified as a subscribe ack message.
      expect(baseMessage, const TypeMatcher<MqttSubscribeAckMessage>());
      final bm = baseMessage as MqttSubscribeAckMessage;
      expect(bm.payload.qosGrants.length, 1);
      expect(bm.payload.qosGrants[0], MqttQos.atMostOnce);
    });
    test('Deserialisation - Single Qos at least once', () {
      // Message Specs________________
      // <90><03><00><02><01>
      final sampleMessage = <int>[0x90, 0x03, 0x00, 0x02, 0x01];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print(
          'Subscribe Ack - Single Qos at least once::${baseMessage.toString()}');
      // Check that the message was correctly identified as a subscribe ack message.
      expect(baseMessage, const TypeMatcher<MqttSubscribeAckMessage>());
      final bm = baseMessage as MqttSubscribeAckMessage;
      expect(bm.payload.qosGrants.length, 1);
      expect(bm.payload.qosGrants[0], MqttQos.atLeastOnce);
    });
    test('Deserialisation - Single Qos exactly once', () {
      // Message Specs________________
      // <90><03><00><02><02>
      final sampleMessage = <int>[0x90, 0x03, 0x00, 0x02, 0x02];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print(
          'Subscribe Ack - Single Qos exactly once::${baseMessage.toString()}');
      // Check that the message was correctly identified as a subscribe ack message.
      expect(baseMessage, const TypeMatcher<MqttSubscribeAckMessage>());
      final bm = baseMessage as MqttSubscribeAckMessage;
      expect(bm.payload.qosGrants.length, 1);
      expect(bm.payload.qosGrants[0], MqttQos.exactlyOnce);
    });
    test('Deserialisation - Single Qos failure', () {
      // Message Specs________________
      // <90><03><00><02><0x80>
      final sampleMessage = <int>[0x90, 0x03, 0x00, 0x02, 0x80];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print('Subscribe Ack - Single Qos failure::${baseMessage.toString()}');
      // Check that the message was correctly identified as a subscribe ack message.
      expect(baseMessage, const TypeMatcher<MqttSubscribeAckMessage>());
      final bm = baseMessage as MqttSubscribeAckMessage;
      expect(bm.payload.qosGrants.length, 1);
      expect(bm.payload.qosGrants[0], MqttQos.failure);
    });
    test('Deserialisation - Single Qos reserved1', () {
      // Message Specs________________
      // <90><03><00><02><0x55>
      final sampleMessage = <int>[0x90, 0x03, 0x00, 0x02, 0x55];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print('Subscribe Ack - Single Qos failure::${baseMessage.toString()}');
      // Check that the message was correctly identified as a subscribe ack message.
      expect(baseMessage, const TypeMatcher<MqttSubscribeAckMessage>());
      final bm = baseMessage as MqttSubscribeAckMessage;
      expect(bm.payload.qosGrants.length, 1);
      expect(bm.payload.qosGrants[0], MqttQos.reserved1);
    });
    test('Deserialisation - Multi Qos', () {
      // Message Specs________________
      // <90><03><00><02><00> <01><02>
      final sampleMessage = <int>[0x90, 0x05, 0x00, 0x02, 0x0, 0x01, 0x02];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print('Subscribe Ack - multi Qos::${baseMessage.toString()}');
      // Check that the message was correctly identified as a subscribe ack message.
      expect(baseMessage, const TypeMatcher<MqttSubscribeAckMessage>());
      final bm = baseMessage as MqttSubscribeAckMessage;
      expect(bm.payload.qosGrants.length, 3);
      expect(bm.payload.qosGrants[0], MqttQos.atMostOnce);
      expect(bm.payload.qosGrants[1], MqttQos.atLeastOnce);
      expect(bm.payload.qosGrants[2], MqttQos.exactlyOnce);
    });
    test('Serialisation - Single Qos at most once', () {
      final expected = typed.Uint8Buffer(5);
      expected[0] = 0x90;
      expected[1] = 0x03;
      expected[2] = 0x00;
      expected[3] = 0x02;
      expected[4] = 0x00;
      final msg = MqttSubscribeAckMessage()
          .withMessageIdentifier(2)
          .addQosGrant(MqttQos.atMostOnce);
      print('Subscribe Ack - Single Qos at most once::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]); // msg type of header + other bits
      expect(actual[1], expected[1]); // remaining length
      expect(actual[2], expected[2]); // message id b1
      expect(actual[3], expected[3]); // message id b2
      expect(actual[4], expected[4]); // QOS
    });
    test('Serialisation - Single Qos at least once', () {
      final expected = typed.Uint8Buffer(5);
      expected[0] = 0x90;
      expected[1] = 0x03;
      expected[2] = 0x00;
      expected[3] = 0x02;
      expected[4] = 0x01;
      final msg = MqttSubscribeAckMessage()
          .withMessageIdentifier(2)
          .addQosGrant(MqttQos.atLeastOnce);
      print('Subscribe Ack - Single Qos at least once::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]); // msg type of header + other bits
      expect(actual[1], expected[1]); // remaining length
      expect(actual[2], expected[2]); // message id b1
      expect(actual[3], expected[3]); // message id b2
      expect(actual[4], expected[4]); // QOS
    });
    test('Serialisation - Single Qos exactly once', () {
      final expected = typed.Uint8Buffer(5);
      expected[0] = 0x90;
      expected[1] = 0x03;
      expected[2] = 0x00;
      expected[3] = 0x02;
      expected[4] = 0x02;
      final msg = MqttSubscribeAckMessage()
          .withMessageIdentifier(2)
          .addQosGrant(MqttQos.exactlyOnce);
      print('Subscribe Ack - Single Qos exactly once::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]); // msg type of header + other bits
      expect(actual[1], expected[1]); // remaining length
      expect(actual[2], expected[2]); // message id b1
      expect(actual[3], expected[3]); // message id b2
      expect(actual[4], expected[4]); // QOS
    });
    test('Serialisation - Multi QOS', () {
      final expected = typed.Uint8Buffer(7);
      expected[0] = 0x90;
      expected[1] = 0x05;
      expected[2] = 0x00;
      expected[3] = 0x02;
      expected[4] = 0x00;
      expected[5] = 0x01;
      expected[6] = 0x02;
      final msg = MqttSubscribeAckMessage()
          .withMessageIdentifier(2)
          .addQosGrant(MqttQos.atMostOnce)
          .addQosGrant(MqttQos.atLeastOnce)
          .addQosGrant(MqttQos.exactlyOnce);
      print('Subscribe Ack - Multi QOS::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]); // msg type of header + other bits
      expect(actual[1], expected[1]); // remaining length
      expect(actual[2], expected[2]); // message id b1
      expect(actual[3], expected[3]); // message id b2
      expect(actual[4], expected[4]); // QOS 1 (Most)
      expect(actual[5], expected[5]); // QOS 2 (Least)
      expect(actual[6], expected[6]); // QOS 3 (Exactly)
    });
    test('Serialisation - Clear grants', () {
      final msg = MqttSubscribeAckMessage()
          .withMessageIdentifier(2)
          .addQosGrant(MqttQos.atMostOnce)
          .addQosGrant(MqttQos.atLeastOnce)
          .addQosGrant(MqttQos.exactlyOnce);
      expect(msg.payload.qosGrants.length, 3);
      msg.payload.clearGrants();
      expect(msg.payload.qosGrants.length, 0);
    });
  });

  group('Unsubscribe', () {
    test('Deserialisation - Single topic', () {
      // Message Specs________________
      // <A2><08><00><03><00><04>fred (Unsubscribe to topic fred)
      final sampleMessage = <int>[
        0xA2,
        0x08,
        0x00,
        0x03,
        0x00,
        0x04,
        'f'.codeUnitAt(0),
        'r'.codeUnitAt(0),
        'e'.codeUnitAt(0),
        'd'.codeUnitAt(0),
      ];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print('Unsubscribe - Single topic::${baseMessage.toString()}');
      // Check that the message was correctly identified as an unsubscribe message.
      expect(baseMessage, const TypeMatcher<MqttUnsubscribeMessage>());
      final bm = baseMessage as MqttUnsubscribeMessage;
      expect(bm.payload.subscriptions.length, 1);
      expect(bm.payload.subscriptions.contains('fred'), isTrue);
    });
    test('Deserialisation - Multi topic', () {
      // Message Specs________________
      // <A2><0E><00><03><00><04>fred<00><04>mark (Unsubscribe to topic fred, mark)
      final sampleMessage = <int>[
        0xA2,
        0x0E,
        0x00,
        0x03,
        0x00,
        0x04,
        'f'.codeUnitAt(0),
        'r'.codeUnitAt(0),
        'e'.codeUnitAt(0),
        'd'.codeUnitAt(0),
        0x00,
        0x04,
        'm'.codeUnitAt(0),
        'a'.codeUnitAt(0),
        'r'.codeUnitAt(0),
        'k'.codeUnitAt(0),
      ];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print('Unsubscribe - Multi topic::${baseMessage.toString()}');
      // Check that the message was correctly identified as an unsubscribe message.
      expect(baseMessage, const TypeMatcher<MqttUnsubscribeMessage>());
      final bm = baseMessage as MqttUnsubscribeMessage;
      expect(bm.payload.subscriptions.length, 2);
      expect(bm.payload.subscriptions.contains('fred'), isTrue);
      expect(bm.payload.subscriptions.contains('mark'), isTrue);
    });
    test('Serialisation - Single topic', () {
      Protocol.version = MqttClientConstants.mqttV31ProtocolVersion;
      final expected = typed.Uint8Buffer(10);
      expected[0] = 0xAA;
      expected[1] = 0x08;
      expected[2] = 0x00;
      expected[3] = 0x03;
      expected[4] = 0x00;
      expected[5] = 0x04;
      expected[6] = 'f'.codeUnitAt(0);
      expected[7] = 'r'.codeUnitAt(0);
      expected[8] = 'e'.codeUnitAt(0);
      expected[9] = 'd'.codeUnitAt(0);
      final msg = MqttUnsubscribeMessage()
          .fromTopic('fred')
          .withMessageIdentifier(3)
          .expectAcknowledgement()
          .isDuplicate();
      print('Unsubscribe - Single topic::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]); // msg type of header + other bits
      expect(actual[1], expected[1]); // remaining length
      expect(actual[2], expected[2]); // Start of VH: MsgID Byte1
      expect(actual[3], expected[3]); // MsgID Byte 2
      expect(actual[4], expected[4]); // Topic Length B1
      expect(actual[5], expected[5]); // Topic Length B2
      expect(actual[6], expected[6]); // f
      expect(actual[7], expected[7]); // r
      expect(actual[8], expected[8]); // e
      expect(actual[9], expected[9]); // d
    });
    test('Serialisation V311 - Single topic', () {
      Protocol.version = MqttClientConstants.mqttV311ProtocolVersion;
      final expected = typed.Uint8Buffer(10);
      expected[0] = 0xA2; // With V3.1.1 the header first byte changes to 162
      expected[1] = 0x08;
      expected[2] = 0x00;
      expected[3] = 0x03;
      expected[4] = 0x00;
      expected[5] = 0x04;
      expected[6] = 'f'.codeUnitAt(0);
      expected[7] = 'r'.codeUnitAt(0);
      expected[8] = 'e'.codeUnitAt(0);
      expected[9] = 'd'.codeUnitAt(0);
      final msg = MqttUnsubscribeMessage()
          .fromTopic('fred')
          .withMessageIdentifier(3)
          .expectAcknowledgement()
          .isDuplicate();
      print('Unsubscribe - Single topic::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]); // msg type of header + other bits
      expect(actual[1], expected[1]); // remaining length
      expect(actual[2], expected[2]); // Start of VH: MsgID Byte1
      expect(actual[3], expected[3]); // MsgID Byte 2
      expect(actual[4], expected[4]); // Topic Length B1
      expect(actual[5], expected[5]); // Topic Length B2
      expect(actual[6], expected[6]); // f
      expect(actual[7], expected[7]); // r
      expect(actual[8], expected[8]); // e
      expect(actual[9], expected[9]); // d
    });
    test('Serialisation - multi topic', () {
      final expected = typed.Uint8Buffer(16);
      expected[0] = 0xA2;
      expected[1] = 0x0E;
      expected[2] = 0x00;
      expected[3] = 0x03;
      expected[4] = 0x00;
      expected[5] = 0x04;
      expected[6] = 'f'.codeUnitAt(0);
      expected[7] = 'r'.codeUnitAt(0);
      expected[8] = 'e'.codeUnitAt(0);
      expected[9] = 'd'.codeUnitAt(0);
      expected[10] = 0x00;
      expected[11] = 0x04;
      expected[12] = 'm'.codeUnitAt(0);
      expected[13] = 'a'.codeUnitAt(0);
      expected[14] = 'r'.codeUnitAt(0);
      expected[15] = 'k'.codeUnitAt(0);
      final msg = MqttUnsubscribeMessage()
          .fromTopic('fred')
          .fromTopic('mark')
          .withMessageIdentifier(3)
          .expectAcknowledgement();
      print('Unubscribe - multi topic::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]); // msg type of header + other bits
      expect(actual[1], expected[1]); // remaining length
      expect(actual[2], expected[2]); // Start of VH: MsgID Byte1
      expect(actual[3], expected[3]); // MsgID Byte 2
      expect(actual[4], expected[4]); // Topic Length B1
      expect(actual[5], expected[5]); // Topic Length B2
      expect(actual[6], expected[6]); // f
      expect(actual[7], expected[7]); // r
      expect(actual[8], expected[8]); // e
      expect(actual[9], expected[9]); // d
      expect(actual[10], expected[10]); // Topic Length B1
      expect(actual[11], expected[11]); // Topic Length B2
      expect(actual[12], expected[12]); // m
      expect(actual[13], expected[13]); // a
      expect(actual[14], expected[14]); // r
      expect(actual[15], expected[15]); // k
    });
    test('Clear subscription', () {
      final msg = MqttUnsubscribeMessage();
      msg.payload.addSubscription('A/Topic');
      msg.payload.clearSubscriptions();
      expect(msg.payload.subscriptions.length, 0);
    });
  });

  group('Unsubscribe Ack', () {
    test('Deserialisation - Valid payload', () {
      // Message Specs________________
      // <B0><02><00><04> (Subscribe ack for message id 4)
      final sampleMessage = <int>[
        0xB0,
        0x02,
        0x00,
        0x04,
      ];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print('Unsubscribe Ack - Valid payload::${baseMessage.toString()}');
      // Check that the message was correctly identified as a publish release message.
      expect(baseMessage, const TypeMatcher<MqttUnsubscribeAckMessage>());
      // Validate the message deserialization
      expect(baseMessage.header!.messageType, MqttMessageType.unsubscribeAck);
      expect(baseMessage.header!.messageSize, 2);
      final bm = baseMessage as MqttUnsubscribeAckMessage;
      expect(bm.variableHeader.messageIdentifier, 4);
    });
    test('Serialisation - Valid payload', () {
      // Publish complete msg with message identifier 4
      final expected = typed.Uint8Buffer(4);
      expected[0] = 0xB0;
      expected[1] = 0x02;
      expected[2] = 0x0;
      expected[3] = 0x4;
      final msg = MqttUnsubscribeAckMessage().withMessageIdentifier(4);
      print('Unsubscribe Ack - Valid payload::${msg.toString()}');
      final actual = MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]); // msg type of header + other bits
      expect(actual[1], expected[1]); // remaining length
      expect(actual[2], expected[2]); // connect ack - compression? always empty
      expect(actual[3], expected[3]); // return code.
    });
  });

  group('Unimplemented', () {
    test('Deserialisation - Invalid payload', () {
      final sampleMessage = <int>[
        0xFF,
        0x02,
        0x00,
        0x04,
      ];
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      var raised = false;
      try {
        final baseMessage = MqttMessage.createFrom(byteBuffer);
        print(baseMessage.toString());
      } on Exception {
        raised = true;
      }
      expect(raised, isTrue);
    });
  });

  group('Issues', () {
    test('81 - extended UTF8 characters must use version V3.1.1', () {
      final sampleMessage = <int>[
        48,
        216,
        2,
        0,
        90,
        47,
        104,
        102,
        112,
        47,
        118,
        49,
        47,
        106,
        111,
        117,
        114,
        110,
        101,
        121,
        47,
        111,
        110,
        103,
        111,
        105,
        110,
        103,
        47,
        98,
        117,
        115,
        47,
        48,
        48,
        49,
        50,
        47,
        48,
        49,
        51,
        51,
        50,
        47,
        50,
        53,
        53,
        48,
        47,
        50,
        47,
        73,
        116,
        195,
        164,
        107,
        101,
        115,
        107,
        117,
        115,
        40,
        77,
        41,
        47,
        49,
        50,
        58,
        48,
        54,
        47,
        49,
        51,
        54,
        50,
        49,
        49,
        51,
        47,
        52,
        47,
        54,
        48,
        59,
        50,
        53,
        47,
        50,
        48,
        47,
        50,
        49,
        47,
        54,
        53,
        123,
        34,
        86,
        80,
        34,
        58,
        123,
        34,
        100,
        101,
        115,
        105,
        34,
        58,
        34,
        53,
        53,
        48,
        34,
        44,
        34,
        100,
        105,
        114,
        34,
        58,
        34,
        50,
        34,
        44,
        34,
        111,
        112,
        101,
        114,
        34,
        58,
        49,
        50,
        44,
        34,
        118,
        101,
        104,
        34,
        58,
        49,
        51,
        51,
        50,
        44,
        34,
        116,
        115,
        116,
        34,
        58,
        34,
        50,
        48,
        49,
        57,
        45,
        48,
        50,
        45,
        50,
        54,
        84,
        49,
        48,
        58,
        53,
        56,
        58,
        52,
        55,
        90,
        34,
        44,
        34,
        116,
        115,
        105,
        34,
        58,
        49,
        53,
        53,
        49,
        49,
        55,
        56,
        55,
        50,
        55,
        44,
        34,
        115,
        112,
        100,
        34,
        58,
        49,
        48,
        46,
        52,
        54,
        44,
        34,
        104,
        100,
        103,
        34,
        58,
        49,
        51,
        48,
        44,
        34,
        108,
        97,
        116,
        34,
        58,
        54,
        48,
        46,
        50,
        50,
        54,
        53,
        50,
        57,
        44,
        34,
        108,
        111,
        110,
        103,
        34,
        58,
        50,
        53,
        46,
        48,
        49,
        53,
        51,
        57,
        55,
        44,
        34,
        97,
        99,
        99,
        34,
        58,
        48,
        46,
        51,
        49,
        44,
        34,
        100,
        108,
        34,
        58,
        45,
        50,
        49,
        52,
        44,
        34,
        111,
        100,
        111,
        34,
        58,
        50,
        50,
        50,
        48,
        50,
        44,
        34,
        100,
        114,
        115,
        116,
        34,
        58,
        48,
        44,
        34,
        111,
        100,
        97,
        121,
        34,
        58,
        34,
        50,
        48,
        49,
        57,
        45,
        48,
        50,
        45,
        50,
        54,
        34,
        44,
        34,
        106,
        114,
        110,
        34,
        58,
        52,
        50,
        52,
        44,
        34,
        108,
        105,
        110,
        101,
        34,
        58,
        50,
        54,
        49,
        44,
        34,
        115,
        116,
        97,
        114,
        116,
        34,
        58,
        34,
        49,
        50,
        58,
        48,
        54,
        34,
        125,
        125
      ];
      Protocol.version = MqttClientConstants.mqttV311ProtocolVersion;
      final buff = typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final byteBuffer = MqttByteBuffer(buff);
      final baseMessage = MqttMessage.createFrom(byteBuffer);
      print(baseMessage);
    });
  });
}
