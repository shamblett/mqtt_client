/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 02/10/2017
 * Copyright :  S.Hamblett
 */
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:mqtt_client/mqtt_client.dart';

Future<int> main() async {
  // Create and connect the client
  final String url = "mqtt.googleapis.com";
  final int port = 443;
  final String clientId = "projects/warm-actor-356/locations/europe-west1/registries/home-sensors/devices/dummy-sensor";
  final String username = "unused";
  final password = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9."
      "eyJpYXQiOjE1MDcyMDExMDUsImV4cCI6MTUwNzI0ODAwMCwiYXVkIjoid2FybS1hY3Rvci0zNTYifQ."
      "Yi2Le8pwSIZw-XWC_nz1fGNmXMCryny3Q1wuZ7gVaFtynAmD89hoEU1gNmSYUw3cWs62JJCQanNDVG_gRoHxqM8ZoPvZsfjmGUTIVlns7EwSqcZ8pCAUGJZz0t87JchKGRVEi_EEAKe1_A2oUP5ifbZEk-NY64KkIGsBSbmQf-c";
  final MqttClient client =
  new MqttClient(url, clientId);
  client.port = port;
  client.secure = true;
  final String currDir = path.current + path.separator;
  //client.trustedCertPath = currDir + path.join("test", "pem", "roots.pem");
  client.logging(true);
  await client.connect(username, password);
  if (client.connectionState == ConnectionState.connected) {
    print("iotcore client connected");
  } else {
    print(
        "ERROR iotcore client connection failed - disconnecting, state is ${client
            .connectionState}");
    client.disconnect();
  }
  // Publish a known topic
//  final String topic = "Dart/SJH/mqtt_client";
//  final typed.Uint8Buffer buff = new typed.Uint8Buffer(5);
//  buff[0] = 'h'.codeUnitAt(0);
//  buff[1] = 'e'.codeUnitAt(0);
//  buff[2] = 'l'.codeUnitAt(0);
//  buff[3] = 'l'.codeUnitAt(0);
//  buff[4] = 'o'.codeUnitAt(0);
//  client.publishMessage(topic, MqttQos.exactlyOnce, buff);
//  print("Sleeping....");
//  await MqttUtilities.asyncSleep(10);
//  print("Disconnecting");
//  client.disconnect();
  return 0;
}
