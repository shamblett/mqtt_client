/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 11/07/2017
 * Copyright :  S.Hamblett
 */
import 'dart:io';
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';

main() async {
  MqttLogger.loggingOn = true;
  final MqttClient client =
  new MqttClient("test.mosquitto.org", "SJHMQTTClient");
  final ConnectionState state = await client.connect();
  print("Mosquitto client connected");
  client.disconnect();
  print("Mosquitto client disconnected");
}
