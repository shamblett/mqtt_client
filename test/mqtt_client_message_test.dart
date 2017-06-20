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

/// Helper methods for test message serialization and deserialization
class MessageSerializationHelper {
  /// Invokes the serialization of a message to get an array of bytes that represent the message.
  static typed.Uint8Buffer getMessageBytes(MqttMessage msg) {
    final typed.Uint8Buffer buff = new typed.Uint8Buffer();
    final MqttByteBuffer ms = new MqttByteBuffer(buff);
    msg.writeTo(ms);
    ms.seek(0);
    final typed.Uint8Buffer msgBytes = ms.read(ms.length);
    return msgBytes;
  }
}

void main() {
  group("Header", () {
    /// Test helper method to call Get Remaining Bytes with a specific value
    typed.Uint8Buffer callGetRemainingBytesWithValue(int value) {
      // validates a payload size of a single byte using the example values supplied in the MQTT spec
      final MqttHeader header = new MqttHeader();
      header.messageSize = value;
      return header.getRemainingLengthBytes();
    }

    /// Creates byte array header with a single byte length
    /// byte1 - the first header byte
    /// length - the length byte
    typed.Uint8Buffer getHeaderBytes(int byte1, int length) {
      final typed.Uint8Buffer tmp = new typed.Uint8Buffer(2);
      tmp[0] = byte1;
      tmp[1] = length;
      return tmp;
    }

    /// Gets the MQTT header from a byte arrayed header.
    MqttHeader getMqttHeader(typed.Uint8Buffer headerBytes) {
      final MqttByteBuffer buff = new MqttByteBuffer(headerBytes);
      return new MqttHeader.fromByteBuffer(buff);
    }

    test("Single byte payload size", () {
      // Validates a payload size of a single byte using the example values supplied in the MQTT spec
      final returnedBytes = callGetRemainingBytesWithValue(127);
      // Check that the count of bytes returned is only 1, and the value of the byte is correct.
      expect(returnedBytes.length, 1);
      expect(returnedBytes[0], 127);
    });
    test("Double byte payload size lower boundary 128", () {
      final returnedBytes = callGetRemainingBytesWithValue(128);
      expect(returnedBytes.length, 2);
      expect(returnedBytes[0], 0x80);
      expect(returnedBytes[1], 0x01);
    });
    test("Double byte payload size upper boundary 16383", () {
      final returnedBytes = callGetRemainingBytesWithValue(16383);
      expect(returnedBytes.length, 2);
      expect(returnedBytes[0], 0xFF);
      expect(returnedBytes[1], 0x7F);
    });
    test("Triple byte payload size lower boundary 16384", () {
      final returnedBytes = callGetRemainingBytesWithValue(16384);
      expect(returnedBytes.length, 3);
      expect(returnedBytes[0], 0x80);
      expect(returnedBytes[1], 0x80);
      expect(returnedBytes[2], 0x01);
    });
    test("Triple byte payload size upper boundary 2097151", () {
      final returnedBytes = callGetRemainingBytesWithValue(2097151);
      expect(returnedBytes.length, 3);
      expect(returnedBytes[0], 0xFF);
      expect(returnedBytes[1], 0xFF);
      expect(returnedBytes[2], 0x7F);
    });
    test("Quadruple byte payload size lower boundary 2097152", () {
      final returnedBytes = callGetRemainingBytesWithValue(2097152);
      expect(returnedBytes.length, 4);
      expect(returnedBytes[0], 0x80);
      expect(returnedBytes[1], 0x80);
      expect(returnedBytes[2], 0x80);
      expect(returnedBytes[3], 0x01);
    });
    test("Quadruple byte payload size upper boundary 268435455", () {
      final returnedBytes = callGetRemainingBytesWithValue(268435455);
      expect(returnedBytes.length, 4);
      expect(returnedBytes[0], 0xFF);
      expect(returnedBytes[1], 0xFF);
      expect(returnedBytes[2], 0xFF);
      expect(returnedBytes[3], 0x7F);
    });
    test("Payload size out of upper range", () {
      final MqttHeader header = new MqttHeader();
      bool raised = false;
      header.messageSize = 2;
      try {
        header.messageSize = 268435456;
      } catch (InvalidPayloadSizeException) {
        raised = true;
      }
      expect(raised, isTrue);
      expect(header.messageSize, 2);
    });
    test("Payload size out of lower range", () {
      final MqttHeader header = new MqttHeader();
      bool raised = false;
      header.messageSize = 2;
      try {
        header.messageSize = -1;
      } catch (InvalidPayloadSizeException) {
        raised = true;
      }
      expect(raised, isTrue);
      expect(header.messageSize, 2);
    });
    test("Duplicate", () {
      final MqttHeader header = new MqttHeader().isDuplicate();
      expect(header.duplicate, isTrue);
    });
    test("Qos", () {
      final MqttHeader header = new MqttHeader().withQos(MqttQos.atMostOnce);
      expect(header.qos, MqttQos.atMostOnce);
    });
    test("Message type", () {
      final MqttHeader header =
      new MqttHeader().asType(MqttMessageType.publishComplete);
      expect(header.messageType, MqttMessageType.publishComplete);
    });
    test("Retain", () {
      final MqttHeader header = new MqttHeader().shouldBeRetained();
      expect(header.retain, isTrue);
    });
    test("Round trip", () {
      final MqttHeader inputHeader = new MqttHeader();
      inputHeader.duplicate = true;
      inputHeader.retain = false;
      inputHeader.messageSize = 1;
      inputHeader.messageType = MqttMessageType.connect;
      inputHeader.qos = MqttQos.atLeastOnce;
      final MqttByteBuffer buffer = new MqttByteBuffer(new typed.Uint8Buffer());
      inputHeader.writeTo(1, buffer);
      buffer.reset();
      final MqttHeader outputHeader = new MqttHeader.fromByteBuffer(buffer);
      expect(inputHeader.duplicate, outputHeader.duplicate);
      expect(inputHeader.retain, outputHeader.retain);
      expect(inputHeader.messageSize, outputHeader.messageSize);
      expect(inputHeader.messageType, outputHeader.messageType);
      expect(inputHeader.qos, outputHeader.qos);
    });
    test("Corrupt header", () {
      final MqttHeader inputHeader = new MqttHeader();
      inputHeader.duplicate = true;
      inputHeader.retain = false;
      inputHeader.messageSize = 268435455;
      inputHeader.messageType = MqttMessageType.connect;
      inputHeader.qos = MqttQos.atLeastOnce;
      final MqttByteBuffer buffer = new MqttByteBuffer(new typed.Uint8Buffer());
      inputHeader.writeTo(268435455, buffer);
      // Fudge the header by making the last bit of the 4th message size byte a 1, therefore making the header
      // invalid because the last bit of the 4th size byte should always be 0 (according to the spec). It's how
      // we know to stop processing the header when reading a full message).
      buffer.seek(0);
      buffer.readByte();
      buffer.readByte();
      buffer.readByte();
      buffer.writeByte(buffer.readByte() | 0xFF);
      bool raised = false;
      try {
        final MqttHeader outputHeader = new MqttHeader.fromByteBuffer(buffer);
        print(outputHeader.toString());
      } catch (InvalidHeaderException) {
        raised = true;
      }
      expect(raised, true);
    });
    test("Corrupt header undersize", () {
      final MqttByteBuffer buffer = new MqttByteBuffer(new typed.Uint8Buffer());
      buffer.writeByte(0);
      buffer.seek(0);
      bool raised = false;
      try {
        final MqttHeader outputHeader = new MqttHeader.fromByteBuffer(buffer);
        print(outputHeader.toString());
      } catch (InvalidHeaderException) {
        raised = true;
      }
      expect(raised, true);
    });
    test("QOS at most once", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(1, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.qos, MqttQos.atMostOnce);
    });
    test("QOS at least once", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(2, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.qos, MqttQos.atLeastOnce);
    });
    test("QOS exactly once", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(4, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.qos, MqttQos.exactlyOnce);
    });
    test("QOS reserved1", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(6, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.qos, MqttQos.reserved1);
    });
    test("Message type reserved1", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(0, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.reserved1);
    });
    test("Message type connect", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(1 << 4, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.connect);
    });
    test("Message type connect ack", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(2 << 4, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.connectAck);
    });
    test("Message type publish", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(3 << 4, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.publish);
    });
    test("Message type publish ack", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(4 << 4, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.publishAck);
    });
    test("Message type publish received", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(5 << 4, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.publishReceived);
    });
    test("Message type publish release", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(6 << 4, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.publishRelease);
    });
    test("Message type publish complete", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(7 << 4, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.publishComplete);
    });
    test("Message type subscribe", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(8 << 4, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.subscribe);
    });
    test("Message type subscribe ack", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(9 << 4, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.subscribeAck);
    });
    test("Message type subscribe", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(8 << 4, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.subscribe);
    });
    test("Message type unsubscribe", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(10 << 4, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.unsubscribe);
    });
    test("Message type unsubscribe ack", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(11 << 4, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.unsubscribeAck);
    });
    test("Message type ping request", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(12 << 4, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.pingRequest);
    });
    test("Message type ping response", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(13 << 4, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.pingResponse);
    });
    test("Message type disconnect", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(14 << 4, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.messageType, MqttMessageType.disconnect);
    });
    test("Duplicate true", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(8, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.duplicate, isTrue);
    });
    test("Duplicate false", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(0, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.duplicate, isFalse);
    });
    test("Retain true", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(1, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.retain, isTrue);
    });
    test("Retain false", () {
      final typed.Uint8Buffer headerBytes = getHeaderBytes(0, 0);
      final MqttHeader header = getMqttHeader(headerBytes);
      expect(header.retain, isFalse);
    });
  });

  group("Connect Flags", () {
    /// Gets the connect flags for a specific byte value
    MqttConnectFlags getConnectFlags(int value) {
      final typed.Uint8Buffer tmp = new typed.Uint8Buffer(1);
      tmp[0] = value;
      final MqttByteBuffer buffer = new MqttByteBuffer(tmp);
      return new MqttConnectFlags.fromByteBuffer(buffer);
    }

    test("WillQos - AtMostOnce", () {
      expect(getConnectFlags(0).willQos, MqttQos.atMostOnce);
    });
    test("WillQos - AtLeastOnce", () {
      expect(getConnectFlags(8).willQos, MqttQos.atLeastOnce);
    });
    test("WillQos - ExactlyOnce", () {
      expect(getConnectFlags(16).willQos, MqttQos.exactlyOnce);
    });
    test("WillQos - Reserved1", () {
      expect(getConnectFlags(24).willQos, MqttQos.reserved1);
    });
    test("Reserved1 true", () {
      expect(getConnectFlags(1).reserved1, isTrue);
    });
    test("Reserved1 false", () {
      expect(getConnectFlags(0).reserved1, isFalse);
    });
    test("Passwordflag true", () {
      expect(getConnectFlags(64).passwordFlag, isTrue);
    });
    test("Passwordflag false", () {
      expect(getConnectFlags(0).passwordFlag, isFalse);
    });
    test("Usernameflag true", () {
      expect(getConnectFlags(128).usernameFlag, isTrue);
    });
    test("Usernameflag false", () {
      expect(getConnectFlags(0).usernameFlag, isFalse);
    });
    test("Cleanstart true", () {
      expect(getConnectFlags(2).cleanStart, isTrue);
    });
    test("Cleanstart false", () {
      expect(getConnectFlags(1).cleanStart, isFalse);
    });
    test("Willretain true", () {
      expect(getConnectFlags(32).willRetain, isTrue);
    });
    test("Willretain false", () {
      expect(getConnectFlags(1).willRetain, isFalse);
    });
    test("Willflag true", () {
      expect(getConnectFlags(4).willFlag, isTrue);
    });
    test("Willflag false", () {
      expect(getConnectFlags(1).willFlag, isFalse);
    });
  });

  group("Variable header", () {
    test("Not enough bytes in string", () {
      final typed.Uint8Buffer tmp = new typed.Uint8Buffer(3);
      tmp[0] = 0;
      tmp[1] = 2;
      tmp[2] = 'm'.codeUnitAt(0);
      final MqttByteBuffer buffer = new MqttByteBuffer(tmp);
      bool raised = false;
      try {
        MqttByteBuffer.readMqttString(buffer);
      } catch (exception) {
        expect(
            exception.toString(),
            "Exception: mqtt_client::ByteBuffer: The buffer did not have enough "
                "bytes for the read operation");
        raised = true;
      }
      expect(raised, isTrue);
    });
    test("Long string is fully read", () {
      final typed.Uint8Buffer tmp = new typed.Uint8Buffer(65537);
      tmp.fillRange(2, tmp.length, 'a'.codeUnitAt(0));
      tmp[0] = (tmp.length - 2) >> 8;
      tmp[1] = (tmp.length - 2) & 0xFF;
      final MqttByteBuffer buffer = new MqttByteBuffer(tmp);
      final String expectedString =
      new String.fromCharCodes(tmp.getRange(2, tmp.length));
      bool raised = false;
      try {
        final String readString = MqttByteBuffer.readMqttString(buffer);
        expect(readString.length, expectedString.length);
        expect(readString, expectedString);
      } catch (exception) {
        print(exception.toString());
        raised = true;
      }
      expect(raised, isFalse);
    });
    test("Not enough bytes to form string", () {
      final typed.Uint8Buffer tmp = new typed.Uint8Buffer(1);
      tmp[0] = 0;
      final MqttByteBuffer buffer = new MqttByteBuffer(tmp);
      bool raised = false;
      try {
        MqttByteBuffer.readMqttString(buffer);
      } catch (exception) {
        expect(
            exception.toString(),
            "Exception: mqtt_client::ByteBuffer: The buffer did not have enough "
                "bytes for the read operation");
        raised = true;
      }
      expect(raised, isTrue);
    });
  });

  group("Connect", () {
    test("Basic deserialization", () {
      // Our test deserialization message, with the following properties. Note this message is not
      // yet a real MQTT message, because not everything is implemented, but it must be modified
      // and ammeneded as work progresses
      //
      // Message Specs________________
      // <10><15><00><06>MQIsdp<03><02><00><1E><00><07>andy111
      final List<int> sampleMessage = [
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
      final typed.Uint8Buffer buff = new typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final MqttByteBuffer byteBuffer = new MqttByteBuffer(buff);
      final MqttMessage baseMessage = MqttMessage.createFrom(byteBuffer);
      print("Connect - Basic deserialization::" + baseMessage.toString());
      // Check that the message was correctly identified as a connect message.
      expect(baseMessage, new isInstanceOf<MqttConnectMessage>());
      // Validate the message deserialization
      expect(baseMessage.header.duplicate, isFalse);
      expect(baseMessage.header.retain, isFalse);
      expect(baseMessage.header.qos, MqttQos.atMostOnce);
      expect(baseMessage.header.messageType, MqttMessageType.connect);
      expect(baseMessage.header.messageSize, 27);
      // Validate the variable header
      expect((baseMessage as MqttConnectMessage).variableHeader.protocolName,
          "MQIsdp");
      expect((baseMessage as MqttConnectMessage).variableHeader.keepAlive, 30);
      expect((baseMessage as MqttConnectMessage).variableHeader.protocolVersion,
          3);
      expect(
          (baseMessage as MqttConnectMessage)
              .variableHeader
              .connectFlags
              .cleanStart,
          isTrue);
      expect(
          (baseMessage as MqttConnectMessage)
              .variableHeader
              .connectFlags
              .willFlag,
          isTrue);
      expect(
          (baseMessage as MqttConnectMessage)
              .variableHeader
              .connectFlags
              .willRetain,
          isTrue);
      expect(
          (baseMessage as MqttConnectMessage)
              .variableHeader
              .connectFlags
              .willQos,
          MqttQos.atLeastOnce);
      // Payload tests
      expect((baseMessage as MqttConnectMessage).payload.clientIdentifier,
          "andy111");
      expect((baseMessage as MqttConnectMessage).payload.willTopic, "m");
      expect((baseMessage as MqttConnectMessage).payload.willMessage, "a");
    });
    test("Payload - invalid client idenfier length", () {
      // Our test deserialization message, with the following properties. Note this message is not
      // yet a real MQTT message, because not everything is implemented, but it must be modified
      // and ammeneded as work progresses
      //
      // Message Specs________________
      // <10><15><00><06>MQIsdp<03><02><00><1E><00><07>andy111andy111andy111andy111
      final List<int> sampleMessage = [
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
        0x1C,
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
      final typed.Uint8Buffer buff = new typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final MqttByteBuffer byteBuffer = new MqttByteBuffer(buff);
      bool raised = false;
      try {
        final MqttMessage baseMessage = MqttMessage.createFrom(byteBuffer);
        print(baseMessage.toString());
      } catch (ClientIdentifierException) {
        raised = true;
      }
      expect(raised, isTrue);
    });
    test("Basic serialization", () {
      final MqttConnectMessage msg = new MqttConnectMessage()
          .withClientIdentifier("mark")
          .keepAliveFor(40)
          .startClean();
      print("Connect - Basic serialization::" + msg.toString());
      final typed.Uint8Buffer mb =
      MessageSerializationHelper.getMessageBytes(msg);
      expect(mb[0], 0x10);
      // VH will = 12, Msg = 6
      expect(mb[1], 0x12);
    });
    test("With will set", () {
      final MqttConnectMessage msg = new MqttConnectMessage()
          .withProtocolName("MQIsdp")
          .withProtocolVersion(3)
          .withClientIdentifier("mark")
          .keepAliveFor(30)
          .startClean()
          .will()
          .withWillQos(MqttQos.atLeastOnce)
          .withWillRetain()
          .withWillTopic("willTopic")
          .withWillMessage("willMessage");
      print("Connect - With will set::" + msg.toString());
      final typed.Uint8Buffer mb =
      MessageSerializationHelper.getMessageBytes(msg);
      expect(mb[0], 0x10);
      // VH will = 12, Msg = 6
      expect(mb[1], 0x2A);
    });
  });

  group("Connect Ack", () {
    test("Deserialisation - Connection accepted", () {
      // Our test deserialization message, with the following properties. Note this message is not
      // yet a real MQTT message, because not everything is implemented, but it must be modified
      // and amended as work progresses
      //
      // Message Specs________________
      // <20><02><00><00>
      final typed.Uint8Buffer sampleMessage = new typed.Uint8Buffer(4);
      sampleMessage[0] = 0x20;
      sampleMessage[1] = 0x02;
      sampleMessage[2] = 0x0;
      sampleMessage[3] = 0x0;
      final MqttByteBuffer byteBuffer = new MqttByteBuffer(sampleMessage);
      final MqttMessage baseMessage = MqttMessage.createFrom(byteBuffer);
      print("Connect Ack - Connection accepted::" + baseMessage.toString());
      // Check that the message was correctly identified as a connect ack message.
      expect(baseMessage, new isInstanceOf<MqttConnectAckMessage>());
      final MqttConnectAckMessage message =
      baseMessage as MqttConnectAckMessage;
      // Validate the message deserialization
      expect(
        message.header.duplicate,
        false,
      );
      expect(
        message.header.retain,
        false,
      );
      expect(message.header.qos, MqttQos.atMostOnce);
      expect(message.header.messageType, MqttMessageType.connectAck);
      expect(message.header.messageSize, 2);
      // Validate the variable header
      expect(message.variableHeader.returnCode,
          MqttConnectReturnCode.connectionAccepted);
    });
    test("Deserialisation - Unacceptable protocol version", () {
      // Our test deserialization message, with the following properties. Note this message is not
      // yet a real MQTT message, because not everything is implemented, but it must be modified
      // and amended as work progresses
      //
      // Message Specs________________
      // <20><02><00><00>
      final typed.Uint8Buffer sampleMessage = new typed.Uint8Buffer(4);
      sampleMessage[0] = 0x20;
      sampleMessage[1] = 0x02;
      sampleMessage[2] = 0x0;
      sampleMessage[3] = 0x1;
      final MqttByteBuffer byteBuffer = new MqttByteBuffer(sampleMessage);
      final MqttMessage baseMessage = MqttMessage.createFrom(byteBuffer);
      print("Connect Ack - Unacceptable protocol version::" +
          baseMessage.toString());
      // Check that the message was correctly identified as a connect ack message.
      expect(baseMessage, new isInstanceOf<MqttConnectAckMessage>());
      final MqttConnectAckMessage message =
      baseMessage as MqttConnectAckMessage;
      // Validate the message deserialization
      expect(
        message.header.duplicate,
        false,
      );
      expect(
        message.header.retain,
        false,
      );
      expect(message.header.qos, MqttQos.atMostOnce);
      expect(message.header.messageType, MqttMessageType.connectAck);
      expect(message.header.messageSize, 2);
      // Validate the variable header
      expect(message.variableHeader.returnCode,
          MqttConnectReturnCode.unacceptedProtocolVersion);
    });
    test("Deserialisation - Identifier rejected", () {
      // Our test deserialization message, with the following properties. Note this message is not
      // yet a real MQTT message, because not everything is implemented, but it must be modified
      // and amended as work progresses
      //
      // Message Specs________________
      // <20><02><00><00>
      final typed.Uint8Buffer sampleMessage = new typed.Uint8Buffer(4);
      sampleMessage[0] = 0x20;
      sampleMessage[1] = 0x02;
      sampleMessage[2] = 0x0;
      sampleMessage[3] = 0x2;
      final MqttByteBuffer byteBuffer = new MqttByteBuffer(sampleMessage);
      final MqttMessage baseMessage = MqttMessage.createFrom(byteBuffer);
      print("Connect Ack - Identifier rejected::" + baseMessage.toString());
      // Check that the message was correctly identified as a connect ack message.
      expect(baseMessage, new isInstanceOf<MqttConnectAckMessage>());
      final MqttConnectAckMessage message =
      baseMessage as MqttConnectAckMessage;
      // Validate the message deserialization
      expect(
        message.header.duplicate,
        false,
      );
      expect(
        message.header.retain,
        false,
      );
      expect(message.header.qos, MqttQos.atMostOnce);
      expect(message.header.messageType, MqttMessageType.connectAck);
      expect(message.header.messageSize, 2);
      // Validate the variable header
      expect(message.variableHeader.returnCode,
          MqttConnectReturnCode.identifierRejected);
    });
    test("Deserialisation - Broker unavailable", () {
      // Our test deserialization message, with the following properties. Note this message is not
      // yet a real MQTT message, because not everything is implemented, but it must be modified
      // and amended as work progresses
      //
      // Message Specs________________
      // <20><02><00><00>
      final typed.Uint8Buffer sampleMessage = new typed.Uint8Buffer(4);
      sampleMessage[0] = 0x20;
      sampleMessage[1] = 0x02;
      sampleMessage[2] = 0x0;
      sampleMessage[3] = 0x3;
      final MqttByteBuffer byteBuffer = new MqttByteBuffer(sampleMessage);
      final MqttMessage baseMessage = MqttMessage.createFrom(byteBuffer);
      print("Connect Ack - Broker unavailable::" + baseMessage.toString());
      // Check that the message was correctly identified as a connect ack message.
      expect(baseMessage, new isInstanceOf<MqttConnectAckMessage>());
      final MqttConnectAckMessage message =
      baseMessage as MqttConnectAckMessage;
      // Validate the message deserialization
      expect(
        message.header.duplicate,
        false,
      );
      expect(
        message.header.retain,
        false,
      );
      expect(message.header.qos, MqttQos.atMostOnce);
      expect(message.header.messageType, MqttMessageType.connectAck);
      expect(message.header.messageSize, 2);
      // Validate the variable header
      expect(message.variableHeader.returnCode,
          MqttConnectReturnCode.brokerUnavailable);
    });
  });
  test("Serialisation - Connection accepted", () {
    final typed.Uint8Buffer expected = new typed.Uint8Buffer(4);
    expected[0] = 0x20;
    expected[1] = 0x02;
    expected[2] = 0x0;
    expected[3] = 0x0;
    final MqttConnectAckMessage msg = new MqttConnectAckMessage()
        .withReturnCode(MqttConnectReturnCode.connectionAccepted);
    print("Connect Ack - Connection accepted::" + msg.toString());
    final typed.Uint8Buffer actual =
    MessageSerializationHelper.getMessageBytes(msg);
    expect(actual.length, expected.length);
    expect(actual[0], expected[0]); // msg type of header
    expect(actual[1], expected[1]); // remaining length
    expect(actual[2], expected[2]); // connect ack - compression? always empty
    expect(actual[3], expected[3]); // return code.
  });
  test("Serialisation - Unacceptable protocol version", () {
    final typed.Uint8Buffer expected = new typed.Uint8Buffer(4);
    expected[0] = 0x20;
    expected[1] = 0x02;
    expected[2] = 0x0;
    expected[3] = 0x1;
    final MqttConnectAckMessage msg = new MqttConnectAckMessage()
        .withReturnCode(MqttConnectReturnCode.unacceptedProtocolVersion);
    print("Connect Ack - Unacceptable protocol version::" + msg.toString());
    final typed.Uint8Buffer actual =
    MessageSerializationHelper.getMessageBytes(msg);
    expect(actual.length, expected.length);
    expect(actual[0], expected[0]); // msg type of header
    expect(actual[1], expected[1]); // remaining length
    expect(actual[2], expected[2]); // connect ack - compression? always empty
    expect(actual[3], expected[3]); // return code.
  });
  test("Serialisation - Identifier rejected", () {
    final typed.Uint8Buffer expected = new typed.Uint8Buffer(4);
    expected[0] = 0x20;
    expected[1] = 0x02;
    expected[2] = 0x0;
    expected[3] = 0x2;
    final MqttConnectAckMessage msg = new MqttConnectAckMessage()
        .withReturnCode(MqttConnectReturnCode.identifierRejected);
    print("Connect Ack - Identifier rejected::" + msg.toString());
    final typed.Uint8Buffer actual =
    MessageSerializationHelper.getMessageBytes(msg);
    expect(actual.length, expected.length);
    expect(actual[0], expected[0]); // msg type of header
    expect(actual[1], expected[1]); // remaining length
    expect(actual[2], expected[2]); // connect ack - compression? always empty
    expect(actual[3], expected[3]); // return code.
  });
  test("Serialisation - Broker unavailable", () {
    final typed.Uint8Buffer expected = new typed.Uint8Buffer(4);
    expected[0] = 0x20;
    expected[1] = 0x02;
    expected[2] = 0x0;
    expected[3] = 0x3;
    final MqttConnectAckMessage msg = new MqttConnectAckMessage()
        .withReturnCode(MqttConnectReturnCode.brokerUnavailable);
    print("Connect Ack - Broker unavailable::" + msg.toString());
    final typed.Uint8Buffer actual =
    MessageSerializationHelper.getMessageBytes(msg);
    expect(actual.length, expected.length);
    expect(actual[0], expected[0]); // msg type of header
    expect(actual[1], expected[1]); // remaining length
    expect(actual[2], expected[2]); // connect ack - compression? always empty
    expect(actual[3], expected[3]); // return code.
  });

  group("Disconnect", () {
    test("Deserialisation", () {
      final typed.Uint8Buffer sampleMessage = new typed.Uint8Buffer(2);
      sampleMessage[0] = 0xE0;
      sampleMessage[1] = 0x0;
      final MqttByteBuffer byteBuffer = new MqttByteBuffer(sampleMessage);
      final MqttMessage baseMessage = MqttMessage.createFrom(byteBuffer);
      print("Disconnect  - Deserialisation::" + baseMessage.toString());
      // Check that the message was correctly identified as a disconnect message.
      expect(baseMessage, new isInstanceOf<MqttDisconnectMessage>());
    });
    test("Serialisation", () {
      final typed.Uint8Buffer expected = new typed.Uint8Buffer(2);
      expected[0] = 0xE0;
      expected[1] = 0x00;
      final MqttDisconnectMessage msg = new MqttDisconnectMessage();
      print("Disconnect - Serialisation::" + msg.toString());
      final typed.Uint8Buffer actual =
      MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]);
      expect(actual[1], expected[1]);
    });
  });

  group("Ping Request", () {
    test("Deserialisation", () {
      final typed.Uint8Buffer sampleMessage = new typed.Uint8Buffer(2);
      sampleMessage[0] = 0xC0;
      sampleMessage[1] = 0x0;
      final MqttByteBuffer byteBuffer = new MqttByteBuffer(sampleMessage);
      final MqttMessage baseMessage = MqttMessage.createFrom(byteBuffer);
      print("Ping Request  - Deserialisation::" + baseMessage.toString());
      // Check that the message was correctly identified as a ping request message.
      expect(baseMessage, new isInstanceOf<MqttPingRequestMessage>());
    });
    test("Serialisation", () {
      final typed.Uint8Buffer expected = new typed.Uint8Buffer(2);
      expected[0] = 0xC0;
      expected[1] = 0x00;
      final MqttPingRequestMessage msg = new MqttPingRequestMessage();
      print("Ping Request - Serialisation::" + msg.toString());
      final typed.Uint8Buffer actual =
      MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]);
      expect(actual[1], expected[1]);
    });
  });

  group("Ping Response", () {
    test("Deserialisation", () {
      final typed.Uint8Buffer sampleMessage = new typed.Uint8Buffer(2);
      sampleMessage[0] = 0xD0;
      sampleMessage[1] = 0x00;
      final MqttByteBuffer byteBuffer = new MqttByteBuffer(sampleMessage);
      final MqttMessage baseMessage = MqttMessage.createFrom(byteBuffer);
      print("Ping Response  - Deserialisation::" + baseMessage.toString());
      // Check that the message was correctly identified as a ping response message.
      expect(baseMessage, new isInstanceOf<MqttPingResponseMessage>());
    });
    test("Serialisation", () {
      final typed.Uint8Buffer expected = new typed.Uint8Buffer(2);
      expected[0] = 0xD0;
      expected[1] = 0x00;
      final MqttPingResponseMessage msg = new MqttPingResponseMessage();
      print("Ping Response - Serialisation::" + msg.toString());
      final typed.Uint8Buffer actual =
      MessageSerializationHelper.getMessageBytes(msg);
      expect(actual.length, expected.length);
      expect(actual[0], expected[0]);
      expect(actual[1], expected[1]);
    });
  });

  group("Publish", () {
    test("Deserialisation - Valid payload", () {
      // Tests basic message deserialization from a raw byte array.
      // Message Specs________________
      // <30><0C><00><04>fredhello!
      final List<int> sampleMessage = [
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
      final typed.Uint8Buffer buff = new typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final MqttByteBuffer byteBuffer = new MqttByteBuffer(buff);
      final MqttMessage baseMessage = MqttMessage.createFrom(byteBuffer);
      print("Publish - Valid payload::" + baseMessage.toString());
      // Check that the message was correctly identified as a publish message.
      expect(baseMessage, new isInstanceOf<MqttPublishMessage>());
      // Validate the message deserialization
      expect(baseMessage.header.duplicate, isFalse);
      expect(baseMessage.header.retain, isFalse);
      expect(baseMessage.header.qos, MqttQos.atMostOnce);
      expect(baseMessage.header.messageType, MqttMessageType.publish);
      expect(baseMessage.header.messageSize, 12);
      // Check the payload
      expect((baseMessage as MqttPublishMessage).payload.message[0],
          'h'.codeUnitAt(0));
      expect((baseMessage as MqttPublishMessage).payload.message[1],
          'e'.codeUnitAt(0));
      expect((baseMessage as MqttPublishMessage).payload.message[2],
          'l'.codeUnitAt(0));
      expect((baseMessage as MqttPublishMessage).payload.message[3],
          'l'.codeUnitAt(0));
      expect((baseMessage as MqttPublishMessage).payload.message[4],
          'o'.codeUnitAt(0));
      expect((baseMessage as MqttPublishMessage).payload.message[5],
          '!'.codeUnitAt(0));
    });
    test("Deserialisation - payload too short", () {
      final List<int> sampleMessage = [
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
      final typed.Uint8Buffer buff = new typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final MqttByteBuffer byteBuffer = new MqttByteBuffer(buff);
      bool raised = false;
      try {
        final MqttMessage baseMessage = MqttMessage.createFrom(byteBuffer);
        print(baseMessage.toString());
      } catch (InvalidPayloadSizeException) {
        raised = true;
      }
      expect(raised, isTrue);
    });
    test("Serialisation - Qos Level 2 Exactly Once", () {
      final List<int> expected = [
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
      final typed.Uint8Buffer payload = new typed.Uint8Buffer(6);
      payload[0] = 'h'.codeUnitAt(0);
      payload[1] = 'e'.codeUnitAt(0);
      payload[2] = 'l'.codeUnitAt(0);
      payload[3] = 'l'.codeUnitAt(0);
      payload[4] = 'o'.codeUnitAt(0);
      payload[5] = '!'.codeUnitAt(0);
      final MqttMessage msg = new MqttPublishMessage()
          .withQos(MqttQos.exactlyOnce)
          .withMessageIdentifier(10)
          .toTopic("fred")
          .publishData(payload);
      print("Publish - Qos Level 2 Exactly Once::" + msg.toString());
      final typed.Uint8Buffer actual =
      MessageSerializationHelper.getMessageBytes(msg);
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
    test("Serialisation - Qos Level 0 No MID", () {
      final List<int> expected = [
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
      final typed.Uint8Buffer payload = new typed.Uint8Buffer(6);
      payload[0] = 'h'.codeUnitAt(0);
      payload[1] = 'e'.codeUnitAt(0);
      payload[2] = 'l'.codeUnitAt(0);
      payload[3] = 'l'.codeUnitAt(0);
      payload[4] = 'o'.codeUnitAt(0);
      payload[5] = '!'.codeUnitAt(0);
      final MqttMessage msg =
      new MqttPublishMessage().toTopic("fred").publishData(payload);
      print("Publish - Qos Level 0 No MID::" + msg.toString());
      final typed.Uint8Buffer actual =
      MessageSerializationHelper.getMessageBytes(msg);
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
    test("Serialisation - With non-default Qos", () {
      final MqttPublishMessage msg = new MqttPublishMessage()
          .toTopic("mark")
          .withQos(MqttQos.atLeastOnce)
          .withMessageIdentifier(4)
          .publishData(new typed.Uint8Buffer(9));
      final typed.Uint8Buffer msgBytes =
      MessageSerializationHelper.getMessageBytes(msg);
      expect(msgBytes.length, 19);
    });
    test("Clear publish data", () {
      final typed.Uint8Buffer data = new typed.Uint8Buffer(2);
      data[0] = 0;
      data[1] = 1;
      final MqttPublishMessage msg = new MqttPublishMessage().publishData(data);
      expect(msg.payload.message.length, 2);
      msg.clearPublishData();
      expect(msg.payload.message.length, 0);
    });
  });

  group("Publish Ack", () {
    test("Deserialisation - Valid payload", () {
      // Tests basic message deserialization from a raw byte array.
      // Message Specs________________
      // <30><0C><00><04>fredhello!
      final List<int> sampleMessage = [
        0x40,
        0x02,
        0x00,
        0x04,
      ];
      final typed.Uint8Buffer buff = new typed.Uint8Buffer();
      buff.addAll(sampleMessage);
      final MqttByteBuffer byteBuffer = new MqttByteBuffer(buff);
      final MqttMessage baseMessage = MqttMessage.createFrom(byteBuffer);
      print("Publish Ack - Valid payload::" + baseMessage.toString());
      // Check that the message was correctly identified as a publish ack message.
      expect(baseMessage, new isInstanceOf<MqttPublishAckMessage>());
      // Validate the message deserialization
      expect(baseMessage.header.messageType, MqttMessageType.publishAck);
      expect(baseMessage.header.messageSize, 2);
      expect(
          (baseMessage as MqttPublishAckMessage)
              .variableHeader
              .messageIdentifier,
          4);
    });
  });
}
