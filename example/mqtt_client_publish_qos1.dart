/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/09/2018
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';

/// A QOS1 publishing example, two QOS one topics are subscribed to and published in quick succession,
/// tests QOS1 protocol handling.
Future<int> main() async {
  final MqttClient client = new MqttClient("test.mosquitto.org", "");
  client.logging(true);
  client.keepAlivePeriod = 20;
  client.onDisconnected = onDisconnected;
  client.onSubscribed = onSubscribed;
  final MqttConnectMessage connMess = new MqttConnectMessage()
      .withClientIdentifier("Mqtt_MyClientUniqueId")
      .keepAliveFor(20) // Must agree with the keep alive set above or not set
      .withWillTopic("willtopic") // If you set this you must set a will message
      .withWillMessage("My Will message")
      .startClean() // Non persistent session for testing
      .withWillQos(MqttQos.atLeastOnce);
  print("EXAMPLE::Mosquitto client connecting....");
  client.connectionMessage = connMess;

  try {
    await client.connect();
  } catch (e) {
    print("EXAMPLE::client exception - $e");
    client.disconnect();
  }

  /// Check we are connected
  if (client.connectionState == ConnectionState.connected) {
    print("EXAMPLE::Mosquitto client connected");
  } else {
    print(
        "EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, state is ${client.connectionState}");
    client.disconnect();
    exit(-1);
  }

  /// Lets try our subscriptions
  print("EXAMPLE:: <<<< SUBCRIBE 1 >>>>");
  final String topic1 = "SJHTopic1"; // Not a wildcard topic
  client.subscribe(topic1, MqttQos.atLeastOnce);
  print("EXAMPLE:: <<<< SUBCRIBE 2 >>>>");
  final String topic2 = "SJHTopic2"; // Not a wildcard topic
  client.subscribe(topic2, MqttQos.atLeastOnce);

  client.updates.listen((List<MqttReceivedMessage> c) {
    final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
    final String pt =
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
    print(
        "EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- ${pt} -->");
    print("");
  });

  final MqttClientPayloadBuilder builder1 = new MqttClientPayloadBuilder();
  builder1.addString("Hello from mqtt_client topic 1");
  print("EXAMPLE:: <<<< PUBLISH 1 >>>>");
  client.publishMessage(topic1, MqttQos.atLeastOnce, builder1.payload);

  final MqttClientPayloadBuilder builder2 = new MqttClientPayloadBuilder();
  builder2.addString("Hello from mqtt_client topic 2");
  print("EXAMPLE:: <<<< PUBLISH 2 >>>>");
  client.publishMessage(topic2, MqttQos.atLeastOnce, builder2.payload);

  print("EXAMPLE::Sleeping....");
  await MqttUtilities.asyncSleep(120);

  print("EXAMPLE::Unsubscribing");
  client.unsubscribe(topic1);
  client.unsubscribe(topic2);

  await MqttUtilities.asyncSleep(2);
  print("EXAMPLE::Disconnecting");
  client.disconnect();
  return 0;
}

/// The subscribed callback
void onSubscribed(String topic) {
  print("EXAMPLE::Subscription confirmed for topic $topic");
}

/// The unsolicited disconnect callback
void onDisconnected() {
  print("EXAMPLE::OnDisconnected client callback - Client disconnection");
  exit(-1);
}
