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

/// A QOS1 publishing example, two QOS one topics are subscribed to and published in quick succession,
/// tests QOS1 protocol handling. This example also shoes how to use batch topic subscription.
Future<int> main() async {
  final client = MqttServerClient('broker.hivemq.com', '');

  /// Set the correct MQTT protocol for mosquito
  client.setProtocolV311();
  client.logging(on: false);
  client.keepAlivePeriod = 20;
  client.onDisconnected = onDisconnected;
  client.onSubscribed = onSubscribed;
  final connMess = MqttConnectMessage()
      .withClientIdentifier('Mqtt_MyClientUniqueIdQ1')
      .withWillTopic('willtopic') // If you set this you must set a will message
      .withWillMessage('My Will message')
      .startClean() // Non persistent session for testing
      .withWillQos(MqttQos.atLeastOnce);
  print('EXAMPLE::Mosquitto client connecting....');
  client.connectionMessage = connMess;

  try {
    await client.connect();
  } on Exception catch (e) {
    print('EXAMPLE::client exception - $e');
    client.disconnect();
  }

  /// Check we are connected
  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print('EXAMPLE::Mosquitto client connected');
  } else {
    print(
      'EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, state is ${client.connectionStatus!.state}',
    );
    client.disconnect();
    exit(-1);
  }

  /// Lets try our subscriptions
  print('EXAMPLE:: <<<< SUBSCRIBING >>>>');
  const topic1 = 'SJHTopic1'; // Not a wildcard topic
  final sub1 = BatchSubscription(topic1, MqttQos.atLeastOnce);
  const topic2 = 'SJHTopic2'; // Not a wildcard topic
  final sub2 = BatchSubscription(topic2, MqttQos.atMostOnce);
  client.subscribeBatch([sub1, sub2]);
  const topic3 = 'SJHTopic3'; // Not a wildcard topic - no subscription

  client.updates!.listen((messageList) {
    final recMess = messageList[0];
    if (recMess is! MqttReceivedMessage<MqttPublishMessage>) return;
    final pubMess = recMess.payload;
    final pt = MqttPublishPayload.bytesToStringAsString(
      pubMess.payload.message,
    );
    print(
      'EXAMPLE::Change notification:: topic is <${recMess.topic}>, payload is <-- $pt -->',
    );
    print('');
  });

  /// If needed you can listen for published messages that have completed the publishing
  /// handshake which is Qos dependant. Any message received on this stream has completed its
  /// publishing handshake with the broker.
  client.published!.listen((MqttPublishMessage message) {
    print(
      'EXAMPLE::Published notification:: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}',
    );
  });

  final builder1 = MqttClientPayloadBuilder();
  builder1.addString('Hello from mqtt_client topic 1');
  print('EXAMPLE:: <<<< PUBLISH 1 >>>>');
  client.publishMessage(topic1, MqttQos.atLeastOnce, builder1.payload!);

  final builder2 = MqttClientPayloadBuilder();
  builder2.addString('Hello from mqtt_client topic 2');
  print('EXAMPLE:: <<<< PUBLISH 2 >>>>');
  client.publishMessage(topic2, MqttQos.atLeastOnce, builder2.payload!);

  final builder3 = MqttClientPayloadBuilder();
  builder3.addString('Hello from mqtt_client topic 3');
  print('EXAMPLE:: <<<< PUBLISH 3 - NO SUBSCRIPTION >>>>');
  client.publishMessage(topic3, MqttQos.atLeastOnce, builder3.payload!);

  print('EXAMPLE::Sleeping....');
  await MqttUtilities.asyncSleep(20);

  print('EXAMPLE::Unsubscribing');
  client.unsubscribe(topic1);

  await MqttUtilities.asyncSleep(5);
  final status = client.getSubscriptionsStatus(topic1);
  if (status != MqttSubscriptionStatus.doesNotExist) {
    print('EXAMPLE::Unsubscribing - failed to unsubscribe batch topic $topic1');
  }
  print('EXAMPLE::Disconnecting');
  client.disconnect();
  return 0;
}

/// The subscribed callback
void onSubscribed(String topic) {
  if (topic == 'SJHTopic1') {
    print('EXAMPLE::Subscription confirmed for topic $topic, this is correct');
  } else {
    print(
      'EXAMPLE::Subscription confirmed for topic $topic, this is incorrect',
    );
  }
}

/// The unsolicited disconnect callback
void onDisconnected() {
  print('EXAMPLE::OnDisconnected client callback - Client disconnection');
}
