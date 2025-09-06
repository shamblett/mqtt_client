/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

import 'package:mqtt_client/mqtt_server_client.dart';

void main() async {
  bool logging = true;

  final mqttClient1 = MqttServerClient(
    'test.mosquitto.org',
    'Unique_ID-1',
    maxConnectionAttempts: 1,
  );
  mqttClient1.logging(on: logging);
  mqttClient1.keepAlivePeriod = 3;
  mqttClient1.onConnected = onConnected1;
  mqttClient1.onDisconnected = onDisconnected1;
  mqttClient1.pongCallback = onPong1;
  await mqttClient1.connect();

  final mqttClient2 = MqttServerClient(
    'test.mosquitto.org',
    'Unique_ID-2',
    maxConnectionAttempts: 1,
  );
  mqttClient2.logging(on: logging);
  mqttClient2.keepAlivePeriod = 3;
  mqttClient2.onConnected = onConnected2;
  mqttClient2.onDisconnected = onDisconnected2;
  mqttClient2.pongCallback = onPong2;
  await mqttClient2.connect();

  final mqttClient3 = MqttServerClient(
    'test.mosquitto.org',
    'Unique_ID-3',
    maxConnectionAttempts: 1,
  );
  mqttClient3.logging(on: logging);
  mqttClient3.keepAlivePeriod = 3;
  mqttClient3.onConnected = onConnected3;
  mqttClient3.onDisconnected = onDisconnected3;
  mqttClient3.pongCallback = onPong3;
  await mqttClient3.connect();

  await Future.delayed(Duration(seconds: 15));

  print('Disconnecting clients');
  mqttClient1.disconnect();
  mqttClient2.disconnect();
  mqttClient3.disconnect();
}

void onConnected1() {
  print('Client 1 connected');
}

void onConnected2() {
  print('Client 2 connected');
}

void onConnected3() {
  print('Client 3 connected');
}

void onDisconnected1() {
  print('Client 1 Disconnected');
}

void onDisconnected2() {
  print('Client 2 Disconnected');
}

void onDisconnected3() {
  print('Client 3 Disconnected');
}

void onPong1() {
  print('Client 1 pong received.');
}

void onPong2() {
  print('Client 2 pong received.');
}

void onPong3() {
  print('Client 3 pong received.');
}
