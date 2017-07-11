/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 11/07/2017
 * Copyright :  S.Hamblett
 */
import 'dart:io';
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:observable/observable.dart';

main() async {
  MqttLogger.loggingOn = true;
  // Connect the client
  final MqttClient client =
  new MqttClient("test.mosquitto.org", "SJHMQTTClient");
  final ConnectionState state = await client.connect();
  if (state == ConnectionState.connected) {
    print("Mosquitto client connected");
  } else {
    print("ERROR Mosquitto client connection failed - disconnecting");
    client.disconnect();
  }
  // Subscribe to a known topic
  final String topic = "test/hw";
  final ChangeNotifier<MqttReceivedMessage> cn =
  client.listenTo(topic, MqttQos.atLeastOnce);
  cn.changes.listen((List<MqttReceivedMessage> c) {
    final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
    final String pt =
    MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
    print("Change notification:: payload is $pt for topic $topic");
  });
  print("Sleeping....");
  await MqttUtilities.asyncSleep(60);
  print("Disconnecting");
  client.disconnect();
}
