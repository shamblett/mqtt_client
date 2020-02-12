import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

Future<int> main() async {
  const broker = 'mq.meeo.xyz';
  const username = 'md-hi75gqj';
  const password = 'user_K8SzwBbLqBEwfIqM';
  final client = MqttServerClient(broker, '');
  client.logging(on: true);
  client.onDisconnected = onDisconnected;
  final connMess = MqttConnectMessage()
      .withClientIdentifier('Mqtt_MyClientUniqueId')
      .keepAliveFor(20) // Must agree with the keep alive set above or not set
      .withWillTopic('willtopic') // If you set this you must set a will message
      .withWillMessage('My Will message')
      .startClean() // Non persistent session for testing
      .withWillQos(MqttQos.atLeastOnce);
  print('EXAMPLE::Mosquitto client connecting....');
  client.connectionMessage = connMess;
  try {
    await client.connect(username, password);
  } on Exception catch (e) {
    print('ERROR: ${e.toString()}');
    exit(-1);
  }

  return 0;
}

/// The unsolicited disconnect callback
void onDisconnected() {
  print('EXAMPLE::OnDisconnected client callback - Client disconnection');
}
