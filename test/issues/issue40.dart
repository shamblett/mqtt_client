import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';

Future<int> main() async {
  MqttClient client;

  Future _connect() async {
    final Completer completer = Completer();
    client = MqttClient("test.mosquitto.org", "");
    client.logging(on: false);

    client.onDisconnected = onDisconnected;

    final MqttConnectMessage connMess = MqttConnectMessage()
        .withClientIdentifier("Mqtt_MyClientUniqueId")
        .startClean();
    print("EXAMPLE::Mosquitto client connecting....");
    client.connectionMessage = connMess;

    try {
      await client.connect();
      return completer.future;
    } catch (e) {
      print("EXAMPLE::client exception - $e");
      client.disconnect();
      completer.completeError(null);
    }

    if (client.connectionStatus.state  == MqttConnectionState.connected) {
      print("EXAMPLE::Mosquitto client connected");
      completer.complete();
    } else {
      print(
          "EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, state is ${client.connectionState}");
      client.disconnect();
      completer.completeError(null);
    }
    return completer.future;
  }

  _connect();
  await MqttUtilities.asyncSleep(1);
  print("Disconnecting 1");
  client.disconnect();
  print("Connection state: ${client.connectionState}");
  // Probably not needed but explicitly allow garbage collection
  client = null;

  await MqttUtilities.asyncSleep(1);

  _connect();
  await MqttUtilities.asyncSleep(1);
  print("Disconnecting 2");
  client.disconnect();
  print("Connection state: ${client.connectionState}");
  client = null;

  await MqttUtilities.asyncSleep(1);

  _connect();
  await MqttUtilities.asyncSleep(1);
  print("Disconnecting 3");
  client.disconnect();
  print("Connection state: ${client.connectionState}");
  client = null;

  await MqttUtilities.asyncSleep(1);

  _connect();
  await MqttUtilities.asyncSleep(1);
  print("Connection state: ${client.connectionState}");

  client.updates.listen((List<MqttReceivedMessage> c) {
    final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
    final String pt =
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    print(
        "EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- ${pt} -->");
    print("");
  });

  print("EXAMPLE::Publishing our topic");

  final String pubTopic = "Dart/Mqtt_client/testtopic";
  final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
  builder.addString("Hello from mqtt_client");

  client.subscribe(pubTopic, MqttQos.exactlyOnce);
  client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload);

  print("EXAMPLE::Sleeping....");
  await MqttUtilities.asyncSleep(120);

  client.disconnect();
  return 0;
}

void onDisconnected() {
  print("EXAMPLE::OnDisconnected client callback - Client disconnection");
  exit(-1);
}
