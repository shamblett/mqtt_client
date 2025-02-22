/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

import 'package:mqtt_client/mqtt_server_client.dart';

void main() async {
  final mqttClient = MqttServerClient.withPort(
    'ws://test.mosquitto.org',
    'Unique_ID',
    8080,
    maxConnectionAttempts: 1,
  );
  mqttClient.useWebSocket = true;
  mqttclient.logging(on: false);
  await mqttClient.connect();
}
