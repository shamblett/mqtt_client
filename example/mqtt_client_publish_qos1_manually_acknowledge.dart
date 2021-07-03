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
/// tests QOS1 protocol handling when manual acknowledgement is in force.
Future<int> main() async {
  final client = MqttServerClient('test.mosquitto.org', '');
  client.logging(on: false);
  client.keepAlivePeriod = 20;
  client.onDisconnected = onDisconnected;
  client.onSubscribed = onSubscribed;
  client.manuallyAcknowledgeQos1 = true;
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
        'EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, state is ${client.connectionStatus!.state}');
    client.disconnect();
    exit(-1);
  }

  /// Lets try our subscriptions
  print('EXAMPLE:: <<<< SUBSCRIBE 1 >>>>');
  const topic1 = 'SJHTopic1'; // Not a wildcard topic
  client.subscribe(topic1, MqttQos.atLeastOnce);
  print('EXAMPLE:: <<<< SUBSCRIBE 2 >>>>');
  const topic2 = 'SJHTopic2'; // Not a wildcard topic
  client.subscribe(topic2, MqttQos.atLeastOnce);
  const topic3 = 'SJHTopic3'; // Not a wildcard topic - no subscription

  // ignore: avoid_annotating_with_dynamic
  try {
    client.updates!.listen((dynamic c) {
      final MqttPublishMessage recMess = c[0].payload;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      print(
          'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
      // Perform any required business logic processing before manually acknowledging
      // the message. You don't have to check anything about the publish message, the
      // acknowledgeQos1Message method will only send an acknowledge for the publish message
      // if it is Qos 1, manual acknowledge has been selected and there is an acknowledge outstanding.
      // If you need to know the acknowledge has been sent the return code will be true.
      print(
          'EXAMPLE::Manually Acknowledging message id ${recMess.variableHeader?.messageIdentifier}');
      final ackRes = client.acknowledgeQos1Message(recMess);
      ackRes!
          ? print('EXAMPLE::Manual acknowledge succeeded')
          : print('EXAMPLE::No Manual acknowledge');
      print(
          'EXAMPLE::Outstanding manual acknowledge message count is ${client.messagesAwaitingManualAcknowledge}');
    });
  } catch (e, s) {
    print(s);
  }

  /// If needed you can listen for published messages that have completed the publishing
  /// handshake which is Qos dependant. Any message received on this stream has completed its
  /// publishing handshake with the broker unless the message is a Qos 1 message and manual
  /// acknowledge has been set on the client, in which case the user must manually acknowledge the
  /// received publish message on completion of any business logic processing.
  client.published!.listen((MqttPublishMessage message) {
    print(
        'EXAMPLE::Published notification:: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}');
    if (message.variableHeader!.topicName == topic3) {
      print('EXAMPLE:: Non subscribed topic received.');
    }
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
  await MqttUtilities.asyncSleep(60);

  print('EXAMPLE::Unsubscribing');
  //client.unsubscribe(topic1);
  client.unsubscribe(topic2);

  await MqttUtilities.asyncSleep(10);
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
  exit(-1);
}
