import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/typed_buffers.dart';

const String broker = 'localhost';
const int port = 1883;
const String topic = 'station1/all';
const int expectedMessages = 1000;

int receivedCount = 0;
int totalBytes = 0;
DateTime? startTime;
DateTime? endTime;

Future<void> main() async {
  final client = MqttServerClient(broker, '');

  client.port = port;
  client.logging(on: false);
  client.keepAlivePeriod = 60;
  client.onDisconnected = onDisconnected;
  client.onConnected = onConnected;

  final connMessage = MqttConnectMessage()
      .withClientIdentifier('dart_mqtt_benchmark_client')
      .startClean()
      .withWillQos(MqttQos.atMostOnce);

  client.connectionMessage = connMessage;

  try {
    await client.connect();
  } catch (e) {
    print('Connection failed - $e');
    client.disconnect();
    return;
  }

  if (client.connectionStatus!.state != MqttConnectionState.connected) {
    print('Connection failed - status is ${client.connectionStatus!.state}');
    client.disconnect();
    return;
  }

  print('Connected to MQTT Broker');

  final subResult = await client.subscribe(topic, MqttQos.atMostOnce);
  if (subResult == null) {
    print('Subscription failed');
    client.disconnect();
    return;
  }
  print('Subscribed to $topic');

  client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
    final recMess = c[0].payload as MqttPublishMessage;
    final dynamic payloadData = recMess.payload.message;

    List<int> byteList;

    if (payloadData is Uint8Buffer) {
      byteList = payloadData.toList();
    } else if (payloadData is List<int>) {
      byteList = payloadData;
    } else if (payloadData is ByteBuffer) {
      byteList = payloadData.asUint8List();
    } else {
      throw Exception('Unknown payload type: ${payloadData.runtimeType}');
    }

    final payload = utf8.decode(byteList);

    if (receivedCount == 0) {
      startTime = DateTime.now();
    }

    receivedCount++;
    totalBytes += byteList.length;

    if (receivedCount >= expectedMessages) {
      endTime = DateTime.now();
      client.disconnect();
    }
  });

  // Wait for messages or timeout after 30 seconds
  final timeout = DateTime.now().add(Duration(seconds: 30));

  while (receivedCount < expectedMessages && DateTime.now().isBefore(timeout)) {
    await Future.delayed(Duration(milliseconds: 50));
  }

  if (receivedCount < expectedMessages) {
    print('Timeout! Received only $receivedCount messages.');
  } else {
    final duration = endTime!.difference(startTime!).inMilliseconds / 1000.0;
    final mbReceived = totalBytes / (1024 * 1024);

    print('All $receivedCount messages received.');
    print('Total receiving time: ${duration.toStringAsFixed(4)} seconds');
    print(
      'Receiving speed: ${(receivedCount / duration).toStringAsFixed(2)} messages/second',
    );
    print(
      'Data throughput: ${(mbReceived / duration).toStringAsFixed(4)} MB/s',
    );
  }
}

void onDisconnected() {
  print('Disconnected from broker');
}

void onConnected() {
  print('Connected callback');
}
