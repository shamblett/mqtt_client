/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:test/test.dart';

Future<int> main() async {
  test('should maintain subscriptions after autoReconnect', () async {
    final client = MqttServerClient.withPort(
        'broker.hivemq.com', 'client-id-123456789', 1883);
    client.autoReconnect = true;
    client.logging(on: true);
    const topic = 'xd/+';

    // Subscribe callback, we do the auto reconnect when we know we have subscribed
    // second time is from the resubscribe so we ignore it.
    var ignoreSubscribe = false;
    void subCB(subTopic) async {
      if (ignoreSubscribe) {
        print('ISSUE: Received re-subscribe callback for our topic - ignoring');
        return;
      }
      if (topic == subTopic) {
        print(
            'ISSUE: Received subscribe callback for our topic - auto reconnecting');
        client.doAutoReconnect(force: true);
      } else {
        print('ISSUE: Received subscribe callback for unknown topic $subTopic');
      }
      ignoreSubscribe = true;
      print('ISSUE: Exiting subscribe callback');
    }

    // New call back for when auto reconnect is complete
    void autoReconnected() async {
      // First unsubscribe
      print('ISSUE: Auto reconnected - Unsubscribing');
      client.unsubscribe(topic);
      await MqttUtilities.asyncSleep(1);

      // Now resubscribe
      print('ISSUE: Auto reconnected - Subscribing');
      client.subscribe(topic, MqttQos.exactlyOnce);
      await MqttUtilities.asyncSleep(1);

      // Now re publish
      print('ISSUE: Auto reconnected - Publishing');
      client.publishMessage('xd/light', MqttQos.exactlyOnce,
          (MqttClientPayloadBuilder()..addUTF8String('xd')).payload);
    }

    // Main test starts here
    print('ISSUE: Main test start');
    client.onSubscribed = subCB; // Subscribe callback
    client.onAutoReconnected = autoReconnected; // Auto reconnected callback
    print('ISSUE: Connecting');
    await client.connect('user', 'password');
    client.subscribe(topic, MqttQos.exactlyOnce);

    // Now publish the message
    print('ISSUE: Publishing');
    client.publishMessage('xd/light', MqttQos.exactlyOnce,
        (MqttClientPayloadBuilder()..addUTF8String('xd')).payload);

    // Listen for our responses.
    print('ISSUE: Listening >>>>');
    final stream = client.updates.expand((event) sync* {
      for (var e in event) {
        MqttPublishMessage message = e.payload;
        yield utf8.decode(message.payload.message);
      }
    }).timeout(Duration(seconds: 20));

    expect(await stream.first, equals('xd'));
    print('ISSUE: Test complete');
  });

  return 0;
}
