import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

int connectionNumber = 1;

Future<void> main() async {
  final client = MqttServerClient('wss://test.mosquitto.org', 'SJH-TEST');
  client.useWebSocket = true;
  client.port = 8081; // ( or whatever your ws port is)
  client.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
  client.keepAlivePeriod = 60;
  client.onConnected = onConnected;
  client.onDisconnected = onDisconnected;
  client.logging(on: false);
  client.setProtocolV311();

  print('EXAMPLE::first connection');
  try {
    await client.connect();
  } on NoConnectionException catch (e) {
    print(e.toString());
  }

  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print('EXAMPLE::Mosquitto wss client connected');
  } else {
    print(
        'EXAMPLE::ERROR Mosquitto client connection $connectionNumber failed - '
        'disconnecting, status is ${client.connectionStatus}');
    client.disconnect();
    exit(-1);
  }

  print('EXAMPLE::sleeping for 60 seconds...');
  await MqttUtilities.asyncSleep(60);

  print('EXAMPLE::disconnecting');
  client.disconnect();

  print('');
  print('EXAMPLE::second connection');
  connectionNumber++;
  try {
    await client.connect();
  } on NoConnectionException catch (e) {
    print(e.toString());
  }

  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print('EXAMPLE::Mosquitto wss client connected');
  } else {
    print(
        'EXAMPLE::ERROR Mosquitto client connection $connectionNumber failed - '
        'disconnecting, status is ${client.connectionStatus}');
    client.disconnect();
    exit(-1);
  }

  print('EXAMPLE::sleeping for 60 seconds...');
  await MqttUtilities.asyncSleep(60);

  print('EXAMPLE::disconnecting');
  client.disconnect();

  print('');
  print('EXAMPLE::end of test');
}

void onDisconnected() {
  print('EXAMPLE::Disconnected, number is $connectionNumber');
}

void onConnected() {
  print('EXAMPLE::Connected, number is $connectionNumber');
}
