/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/09/2018
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// A QOS2 publishing example, two QOS two topics are subscribed to and published in quick succession,
/// tests QOS2 protocol handling.
Future<int> main() async {
  final client = MqttServerClient('broker.hivemq.com', '');

  /// Set the correct MQTT protocol for mosquito
  client.setProtocolV311();
  client.logging(on: false);
  client.keepAlivePeriod = 20;
  client.onDisconnected = onDisconnected;
  client.onSubscribed = onSubscribed;
  final connMess = MqttConnectMessage()
      .withClientIdentifier('Mqtt_MyClientUniqueIdQ2')
      .withWillTopic('willtopic') // If you set this you must set a will message
      .withWillMessage('My Will message')
      .startClean() // Non persistent session for testing
      .withWillQos(MqttQos.atLeastOnce);
  print('EXAMPLE::Hive client connecting....');
  client.connectionMessage = connMess;

  try {
    await client.connect();
  } on Exception catch (e) {
    print('EXAMPLE::client exception - $e');
    client.disconnect();
  }

  /// Check we are connected
  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print('EXAMPLE::Hive client connected');
  } else {
    print(
      'EXAMPLE::ERROR Hive client connection failed - disconnecting, state is ${client.connectionStatus!.state}',
    );
    client.disconnect();
    exit(-1);
  }

  /// Lets try our subscriptions
  print('EXAMPLE:: <<<< SUBSCRIBE 1 >>>>');
  const topic1 = 'SJHTopic1'; // Not a wildcard topic
  client.subscribe(topic1, MqttQos.exactlyOnce);
  print('EXAMPLE:: <<<< SUBSCRIBE 2 >>>>');
  const topic2 = 'SJHTopic2'; // Not a wildcard topic
  client.subscribe(topic2, MqttQos.exactlyOnce);

  client.updates!.listen((messageList) {
    final recMess = messageList[0];
    final pubMess = recMess.payload as MqttPublishMessage;
    final pt = MqttPublishPayload.bytesToStringAsString(
      pubMess.payload.message,
    );
    print(
      'EXAMPLE::Change notification:: topic is <${recMess.topic}>, payload is <-- $pt -->',
    );
  });

  /// If needed you can listen for published messages that have completed the publishing
  /// handshake which is Qos dependant. Any message received on this stream has completed its
  /// publishing handshake with the broker.
  // ignore: avoid_types_on_closure_parameters
  client.published!.listen((MqttPublishMessage message) {
    print(
      'EXAMPLE::Published notification:: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}',
    );
  });

  final builder1 = MqttClientPayloadBuilder();
  builder1.addString('Hello from mqtt_client topic 1');
  print('EXAMPLE:: <<<< PUBLISH 1 >>>>');
  client.publishMessage(topic1, MqttQos.exactlyOnce, builder1.payload!);

  final builder2 = MqttClientPayloadBuilder();
  builder2.addString('Hello from mqtt_client topic 2');
  print('EXAMPLE:: <<<< PUBLISH 2 >>>>');
  client.publishMessage(topic2, MqttQos.exactlyOnce, builder2.payload!);

  print('EXAMPLE::Sleeping....');
  await MqttUtilities.asyncSleep(20);

  print('EXAMPLE::Unsubscribing');
  client.unsubscribe(topic1);
  client.unsubscribe(topic2);

  await MqttUtilities.asyncSleep(5);
  print('EXAMPLE::Disconnecting');
  client.disconnect();
  return 0;
}

/// The subscribed callback
void onSubscribed(String topic) {
  print('EXAMPLE::Subscription confirmed for topic $topic');
}

/// The unsolicited disconnect callback
void onDisconnected() {
  print('EXAMPLE::OnDisconnected client callback - Client disconnection');
}
