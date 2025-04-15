/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 11/07/2017
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

Future<int> main() async {
  // Create and connect the client for websocket usage. The scheme must be ws:// otherwise
  // Dart IO will not create the websocket
  final client = MqttServerClient('ws://iot.eclipse.org/ws', 'SJHMQTTClient');
  client.useWebSocket = true;
  client.port = 80;
  client.logging(on: false);
  await client.connect();
  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print('Mosquitto client connected');
  } else {
    print(
      'ERROR Mosquitto client connection failed - disconnecting, state is ${client.connectionStatus}',
    );
    client.disconnect();
  }
  // Subscribe to a known topic
  const topic = 'test/hw';
  client.subscribe(topic, MqttQos.exactlyOnce);
  client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
    final recMess = c![0].payload as MqttPublishMessage;
    final pt = MqttPublishPayload.bytesToStringAsString(
      recMess.payload.message,
    );
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
