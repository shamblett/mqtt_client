import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

// ignore_for_file: deprecated_member_use_from_same_package

Future<int> main() async {
  MqttServerClient client;

  Future _connect() async {
    final completer = Completer();
    client = MqttServerClient('test.mosquitto.org', '');
    client.logging(on: false);

    client.onDisconnected = onDisconnected;

    final connMess = MqttConnectMessage()
        .withClientIdentifier('Mqtt_MyClientUniqueId')
        .startClean();
    print('EXAMPLE::Mosquitto client connecting....');
    client.connectionMessage = connMess;

    try {
      await client.connect();
      return completer.future;
    } catch (e) {
      print('EXAMPLE::client exception - $e');
      client.disconnect();
      completer.completeError(null);
    }

    if (client.connectionStatus.state == MqttConnectionState.connected) {
      print('EXAMPLE::Mosquitto client connected');
      completer.complete();
    } else {
      print(
          'EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, state is ${client.connectionState}');
      client.disconnect();
      completer.completeError(null);
    }
    return completer.future;
  }

  await _connect();
  await MqttUtilities.asyncSleep(1);
  print('Disconnecting 1');
  client.disconnect();
  print('Connection state: ${client.connectionState}');
  // Probably not needed but explicitly allow garbage collection
  client = null;

  await MqttUtilities.asyncSleep(1);

  await _connect();
  await MqttUtilities.asyncSleep(1);
  print('Disconnecting 2');
  client.disconnect();
  print('Connection state: ${client.connectionState}');
  client = null;

  await MqttUtilities.asyncSleep(1);

  await _connect();
  await MqttUtilities.asyncSleep(1);
  print('Disconnecting 3');
  client.disconnect();
  print('Connection state: ${client.connectionState}');
  client = null;

  await MqttUtilities.asyncSleep(1);

  await _connect();
  await MqttUtilities.asyncSleep(1);
  print('Connection state: ${client.connectionState}');

  client.updates.listen((List<MqttReceivedMessage> c) {
    final recMess = c[0].payload as MqttPublishMessage;
    final pt =
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    print(
        'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- ${pt} -->');
    print('');
  });

  print('EXAMPLE::Publishing our topic');

  final pubTopic = 'Dart/Mqtt_client/testtopic';
  final builder = MqttClientPayloadBuilder();
  builder.addString('Hello from mqtt_client');

  client.subscribe(pubTopic, MqttQos.exactlyOnce);
  client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload);

  print('EXAMPLE::Sleeping....');
  await MqttUtilities.asyncSleep(120);

  client.disconnect();
  return 0;
}

void onDisconnected() {
  print('EXAMPLE::OnDisconnected client callback - Client disconnection');
}
