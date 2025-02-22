/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:test/test.dart';

Future<int> main() async {
  test('State preservation across instances', () async {
    var client = MqttServerClient.withPort(
        'test.mosquitto.org', 'client-id-123456789', 1883);
    client.autoReconnect = true;
    client.logging(on: false);
    const topic = 'xd/+';
    await client.connect();
    expect(client.connectionStatus.state, MqttConnectionState.connected);
    print("TEST - First subscription");
    var firstSub = client.subscribe(topic, MqttQos.exactlyOnce);
    await MqttUtilities.asyncSleep(2);
    expect(client.getSubscriptionsStatus(topic), MqttSubscriptionStatus.active);
    expect(client.autoReconnect, isTrue);

    // OK, reinstantiate the client and do some basic checks before we connect
    sleep(Duration(seconds: 5));
    client = MqttServerClient.withPort(
        'test.mosquitto.org', 'client-id-123456789', 1883);
    client.logging(on: false);
    client.autoReconnect = true;
    client.resubscribeOnAutoReconnect = false;
    expect(client.connectionStatus.state, MqttConnectionState.disconnected);
    expect(client.autoReconnect, isTrue);

    // Connect
    print("TEST - reconnecting new client");
    await client.connect();
    print("TEST - new client reconnected");

    // Re check our state
    expect(client.connectionStatus.state, MqttConnectionState.connected);
    expect(client.autoReconnect, isTrue);
    expect(client.getSubscriptionsStatus(topic),
        MqttSubscriptionStatus.doesNotExist);

    print("TEST - Second subscription");
    var secondSub = client.subscribe(topic, MqttQos.exactlyOnce);
    await MqttUtilities.asyncSleep(5);
    expect(client.getSubscriptionsStatus(topic), MqttSubscriptionStatus.active);
  }, timeout: Timeout.factor(2));

  return 0;
}
