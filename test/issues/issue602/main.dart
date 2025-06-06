import 'dart:async';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() async {
  final client = MqttServerClient('localhost', 'dart_client1111');
  client.port = 1883;
  client.logging(on: true, logPayloads: false);
  final connMess = MqttConnectMessage();

  client.connectionMessage = connMess;

  int i = 0;

  client.onConnected = () {
    print('Connected to broker');
    client.subscribe('station1/all', MqttQos.atMostOnce);
  };

  client.onDisconnected = () {
    print('Disconnected from broker');
  };

  try {
    print('Connecting...');
    final connResult = await client.connect();

    if (connResult?.state == MqttConnectionState.connected) {
      print('Connected successfully');

      // Now it's safe to listen
      client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        i++;
        print(i);

        // Optional: read message payload
        // final payload =
        //     MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        // print('Message received: $payload');
      });
    } else {
      print('Connection failed - state is ${connResult?.state}');
      client.disconnect();
    }
  } catch (e) {
    print('Exception during connection: $e');
    client.disconnect();
    return;
  }

  // Keep running
  await Future.delayed(Duration(days: 365));
}
