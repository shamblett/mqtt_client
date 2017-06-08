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
}
