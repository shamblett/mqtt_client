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
  test('Should maintain subscriptions after autoReconnect', () async {
    final client =
        MqttServerClient.withPort('localhost', 'client-id-123456789', 1883);
    client.autoReconnect = true;
    client.logging(on: false);
    const topic = 'xd/+';
    var autoCompleteCount = 0;

    // Subscribe callback, we do the auto reconnect when we know we have subscribed
    // second time is from the resubscribe so re publish.
    var ignoreSubscribe = false;
    void subCB(subTopic) async {
      if (ignoreSubscribe) {
        print(
            'ISSUE: Received re-subscribe callback for our topic - re publishing');
        client.publishMessage('xd/light', MqttQos.exactlyOnce,
            (MqttClientPayloadBuilder()..addUTF8String('xd')).payload);
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

    void autoComplete() {
      autoCompleteCount++;
    }

    void disconnected() {
      print('ISSUE: Client is disconnected');
    }

    void preAuto() {
      print('ISSUE: Pre auto reconnect entered');
    }

    // Main test starts here
    print('ISSUE: Main test start');
    client.onSubscribed = subCB; // Subscribe callback
    client.onAutoReconnected = autoComplete; // Auto Reconnected callback
    client.onDisconnected = disconnected;
    client.onAutoReconnect = preAuto;

    print('ISSUE: Connecting');
    await client.connect();
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
    }).timeout(Duration(seconds: 7));

    expect(await stream.first, equals('xd'));

    var delay = MqttCancellableAsyncSleep(10000);
    print(
        'ISSUE: Second disconnect ..... <<< Stop and restart the broker here');
    await delay.sleep();
    expect(autoCompleteCount, 1);
    print('ISSUE: Test complete');
  }, timeout: Timeout.factor(2));

  return 0;
}
