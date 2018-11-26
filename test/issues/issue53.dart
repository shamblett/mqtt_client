import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:mqtt_client/mqtt_client.dart';

Future<int> main() async {
  MqttClient client;

  const String clientId = 'SJHMQTTTest_53';
  client = MqttClient('test.mosquitto.org', clientId);
  client.setProtocolV311();
  client.keepAlivePeriod = 20;
  client.port = 1883;
  client.logging(on: true);

  client.onDisconnected = () {
    print('==> Disconnected | Time: ${DateTime.now().toUtc()}');
    client.disconnect();
    exit(-1);
  };

  client.connectionMessage = MqttConnectMessage()
      .withClientIdentifier(clientId);

  client.connectionMessage.startClean();

  await client.connect();

  final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
  builder.addString(
    json.encode(
      <String,dynamic>{
        'type': 'msgText',
        'data': 'message data',
        'identifier': Random().nextInt(1000000),
      },
    ),
  );

  client.publishMessage('u\SJHTest', MqttQos.exactlyOnce, builder.payload);

  print('Sleeping...');
  await MqttUtilities.asyncSleep(120);

  print('Client exiting');

  return 0;
  
}
