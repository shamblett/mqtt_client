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
  });
}
