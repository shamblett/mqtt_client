/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:test/test.dart';

/// Sleep function that block asynchronous activity.
/// Time units are seconds
void syncSleep(int seconds) {
  sleep(Duration(seconds: seconds));
}

Future<int> main() async {
  test('should maintain subscriptions after autoReconnect', () async {
    final client = MqttServerClient.withPort(
        'broker.hivemq.com', 'client-id-123456789', 1883);
    client.autoReconnect = true;
    client.logging(on: true);
    await client.connect('user', 'password');
    client.subscribe('xd/+', MqttQos.exactlyOnce);

    client.doAutoReconnect(force: true); // this line breaks the test
    //client.subscribe('xd/+', MqttQos.exactlyOnce); // uncommenting this line doesn't help

    final stream = client.updates.expand((event) sync* {
      for (var e in event) {
        MqttPublishMessage message = e.payload;
        yield utf8.decode(message.payload.message);
      }
    }).timeout(Duration(seconds: 5));

    client.publishMessage('xd/light', MqttQos.exactlyOnce,
        (MqttClientPayloadBuilder()..addUTF8String('xd')).payload);

    expect(await stream.first, equals('xd'));
  });

  return 0;
}
