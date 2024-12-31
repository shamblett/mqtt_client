import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

Future<void> main() async {
  final client = MqttServerClient('test.mosquitto.org', '');
  final topic2 = '/abc/123';
  client.setProtocolV311();
  client.port = 1883;
  client.logging(on: true);
  client.keepAlivePeriod = 60;
// client.autoReconnect = true;
  final connMess = MqttConnectMessage()
      .withClientIdentifier('mqttx_001346fd')
      .startClean(); // Non persistent session for testing
  client.connectionMessage = connMess;
  try {
    await client.connect();
  } on Exception {
    client.disconnect();
  }

  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print('EXAMPLE::Mosquitto client connected');
  } else {
    client.disconnect();
    // exit(-1);
  }

  client.subscribe(topic2, MqttQos.exactlyOnce);

  client.updates!.listen((messageList) {
    final recMess = messageList[0];
    if (recMess.payload is MqttPublishMessage) {
      MqttPublishMessage message = recMess.payload as MqttPublishMessage;
      MqttPublishPayload payload = message.payload;
      String str = utf8.decode(payload.message);
      print('EXAMPLE::Change notification:: topic is <${recMess.topic}>,$str');
    }
  });

  client.published!.listen((MqttPublishMessage message) {
    String str = utf8.decode(message.payload.message);
    print(
        'EXAMPLE::Published notification:: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos},$str');
  });

  await Future.delayed(Duration(seconds: 10));
}
