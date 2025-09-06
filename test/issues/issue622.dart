/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

import 'package:mqtt_client/mqtt_server_client.dart';

void main() async {
  final mqttClient1 = MqttServerClient(
    'test.mosquitto.org',
    'Unique_ID-1',
    maxConnectionAttempts: 1,
  );
  mqttClient1.logging(on: true);
  mqttClient1.onConnected = onConnected1;
  await mqttClient1.connect();

  final mqttClient2 = MqttServerClient(
    'test.mosquitto.org',
    'Unique_ID-2',
    maxConnectionAttempts: 1,
  );
  mqttClient2.logging(on: true);
  mqttClient2.onConnected = onConnected2;
  await mqttClient2.connect();

  final mqttClient3 = MqttServerClient(
    'test.mosquitto.org',
    'Unique_ID-3',
    maxConnectionAttempts: 1,
  );
  mqttClient3.logging(on: true);
  mqttClient3.onConnected = onConnected3;
  await mqttClient3.connect();
}

void onConnected1() {
  print('Client 1 connected');
}

void onConnected2() {
  print('Client 2 connected');
}

void onConnected3() {
  print('Client 2 connected');
}