/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 11/07/2017
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';

// ignore_for_file: cascade_invocations
// ignore_for_file: unnecessary_final
// ignore_for_file: omit_local_variable_types
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: avoid_print
// ignore_for_file: avoid_types_on_closure_parameters

Future<int> main() async {
  // Create and connect the client
  final MqttClient client = MqttClient('iot.eclipse.org', 'SJHMQTTClient');
  client.logging(on: true);
  await client.connect();
  if (client.connectionStatus.state == MqttConnectionState.connected) {
    print('Mosquitto client connected');
  } else {
    print(
        'ERROR Mosquitto client connection failed - disconnecting, state is ${client.connectionStatus}');
    client.disconnect();
  }
  // Subscribe to a known topic
  const String topic = 'test/hw';
  client.subscribe(topic, MqttQos.exactlyOnce);
  client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
    final MqttPublishMessage recMess = c[0].payload;
    final String pt =
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
    print('Change notification:: payload is <$pt> for topic <$topic>');
  });
  print('Sleeping....');
  await MqttUtilities.asyncSleep(90);
  print('Unsubscribing');
  client.unsubscribe(topic);
  await MqttUtilities.asyncSleep(2);
  print('Disconnecting');
  client.disconnect();
  return 0;
}
