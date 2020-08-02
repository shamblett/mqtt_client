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
    void subCB(subTopic) async {
      if (topic == subTopic) {
        print(
            'ISSUE: Received subscribe callback for our topic - auto reconnecting');
        client.doAutoReconnect(force: true);
        do {
          if (client.connectionStatus.state != MqttConnectionState.connected) {
            await MqttUtilities.asyncSleep(1);
          } else {
            print(
                'ISSUE: Received subscribe callback for our topic - reconnected - publishing');
            // Now publish the message
            client.publishMessage('xd/light', MqttQos.exactlyOnce,
                (MqttClientPayloadBuilder()..addUTF8String('xd')).payload);
            break;
          }
        } while (true);
      } else {
        print('ISSUE: Received subscribe callback for unknown topic $subTopic');
      }
      print('ISSUE: Exiting subscribe callback');
    }

    client.onSubscribed = subCB;
    print('ISSUE: Connecting');
    await client.connect('user', 'password');
    client.subscribe(topic, MqttQos.exactlyOnce);

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
