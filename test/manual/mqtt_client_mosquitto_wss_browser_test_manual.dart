/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 24/01/2020
 * Copyright :  S.Hamblett
 */

@TestOn('browser')
library;

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:test/test.dart';

void main() {
  const mosquittoServer = 'wss://test.mosquitto.org';
  const mosquittoPort = 8081;
  const testClientId = 'syncMqttTests';

  group('Broker tests', () {
    test('Connect mosquitto test broker', () async {
      var pongCount = 0;
      void connectCallback() {
        print('Browser client connected callback');
      }

      void pongCallback() {
        print('Browser client pong callback');
        pongCount++;
      }

      final sleeper = MqttCancellableAsyncSleep(25000);
      final client = MqttBrowserClient(mosquittoServer, testClientId);
      client.port = mosquittoPort;
      client.logging(on: false);
      client.onConnected = connectCallback;
      client.pongCallback = pongCallback;
      client.keepAlivePeriod = 10;
      client.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
      final connMess = MqttConnectMessage()
          .withClientIdentifier(testClientId)
          .withWillTopic('willtopic')
          .withWillMessage('My Will message')
          .startClean() // Non persistent session for testing
          .withWillQos(MqttQos.atLeastOnce);
      client.connectionMessage = connMess;
      var ok = true;
      try {
        await client.connect();
        var connectionOK = false;
        if (client.connectionStatus!.state == MqttConnectionState.connected) {
          print('Browser client connected locally');
          connectionOK = true;
        } else {
          print(
            'Browser client connection failed - disconnecting, status is ${client.connectionStatus}',
          );
          client.disconnect();
        }
        await sleeper.sleep();
        if (connectionOK) {
          if (pongCount == 2) {
            print('Browser client disconnecting normally');
            client.disconnect();
          }
        }
      } on NoConnectionException {
        print(
          '>>>>> TEST NOT OK - No connection exception thrown, cannot connect to Mosquitto',
        );
        ok = false;
      }
      expect(ok, isTrue);
    }, timeout: Timeout.factor(2));
  });
}
