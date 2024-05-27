/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

Future<int> main() async {
  final client = MqttServerClient.withPort('localhost', 'SJHIssueRx', 1883);

  client.logging(on: false);
  client.setProtocolV311();
  client.autoReconnect = true;
  const topic = 'counter';
  final connMess = MqttConnectMessage();
  client.connectionMessage = connMess;

  print('ISSUE: Connecting');
  await client.connect();

  // Subscribe to counter, Qos 1
  client.subscribe(topic, MqttQos.atLeastOnce);
  print(
      'EXAMPLE:: Sleeping to allow the subscription acknowledges to be received....');
  await MqttUtilities.asyncSleep(2);

  // Listen for the counter messages
  print('ISSUE::Listening......');
  client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
    final recMess = c[0].payload as MqttPublishMessage;
    final payload = recMess.payload.message;
    if (payload != null) {
      final counterValue = payload[0];
      print('ISSUE::Change notification:: counter received is $counterValue');
    } else {
      print('ISSUE - ERROR payload is null');
    }
  });

  await MqttUtilities.asyncSleep(60);

  print('ISSUE: Test complete');
  client.disconnect();

  return 0;
}
