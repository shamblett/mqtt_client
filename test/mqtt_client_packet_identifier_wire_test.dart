@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart';

import 'support/mqtt_client_mock_socket.dart';

class _Socket extends MqttMockSocketSimpleConnect {
  final publishes = <MqttPublishMessage>[];
  int qos0Count = 0;

  @override
  void add(List<int> data) {
    if (data.first >> 4 == 3) {
      if ((data.first >> 1) & 3 == 0) {
        qos0Count++;
        return;
      }
      final stream = MqttByteBuffer(Uint8Buffer()..addAll(data));
      publishes.add(MqttMessage.createFrom(stream) as MqttPublishMessage);
    }
    super.add(data);
  }

  void acknowledge(int id) =>
      onDataFunc(Uint8List.fromList([0x40, 2, id >> 8, id & 255]));
}

void main() {
  test(
    'MQTT-2.3.1-2/3: wire IDs and published notifications survive counter wrap',
    () async {
      final socket = _Socket();
      await IOOverrides.runZoned(
        () async {
          final client = MqttServerClient(
            'localhost',
            'packet-id-wrap',
            maxConnectionAttempts: 1,
          )..setProtocolV311();
          addTearDown(client.disconnect);
          await client.connect();
          final completed = StreamIterator(client.published!);
          addTearDown(completed.cancel);
          final firstPayload =
              (MqttClientPayloadBuilder()..addUTF8String('first')).payload!;
          final secondPayload =
              (MqttClientPayloadBuilder()..addUTF8String('second')).payload!;
          final first = client.publishMessage(
            'telemetry',
            MqttQos.atLeastOnce,
            firstPayload,
          );
          // Advance exclusively through public client calls. No dispenser access.
          for (var i = 0; i < 32766; i++) {
            client.publishMessage(
              'telemetry',
              MqttQos.atMostOnce,
              firstPayload,
            );
          }
          final second = client.publishMessage(
            'telemetry',
            MqttQos.atLeastOnce,
            secondPayload,
          );
          expect(second, isNot(first));
          expect(socket.qos0Count, 32766);
          expect(
            socket.publishes.map(
              (message) => message.variableHeader!.messageIdentifier,
            ),
            [first, second],
          );

          socket.acknowledge(first);
          expect(await completed.moveNext(), isTrue);
          expect(completed.current.variableHeader!.messageIdentifier, first);
          expect(completed.current.payload.message, firstPayload);
          socket.acknowledge(second);
          expect(await completed.moveNext(), isTrue);
          expect(completed.current.variableHeader!.messageIdentifier, second);
          expect(completed.current.payload.message, secondPayload);
        },
        socketConnect:
            (
              dynamic host,
              int port, {
              dynamic sourceAddress,
              int sourcePort = 0,
              Duration? timeout,
            }) async => socket,
      );
    },
  );
}
