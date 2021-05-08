/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 24/01/2020
 * Copyright :  S.Hamblett
 */

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:test/test.dart';

@TestOn('browser')
void main() {
  const mockBrokerAddressWsNoScheme = 'localhost.com';
  const mockBrokerAddressWsBad = '://localhost.com';
  const testClientId = 'syncMqttTests';
  const localServer = 'ws://127.0.0.1/ws';
  const localPort = 8090;

  group('Connection parameters', () {
    test('Invalid URL', () async {
      try {
        final client = MqttBrowserClient(mockBrokerAddressWsBad, testClientId);
        client.logging(on: true);
        await client.connect();
      } on Exception catch (e) {
        expect(e is NoConnectionException, true);
        expect(
            e.toString(),
            'mqtt-client::NoConnectionException: '
            'MqttBrowserWsConnection::connect - The URI supplied for the WS connection is not valid - ://localhost.com');
      }
    });

    test('Invalid URL - bad scheme', () async {
      try {
        final client =
            MqttBrowserClient(mockBrokerAddressWsNoScheme, testClientId);
        client.logging(on: true);
        await client.connect();
      } on Exception catch (e) {
        expect(e is NoConnectionException, true);
        expect(
            e.toString(),
            'mqtt-client::NoConnectionException: '
            'MqttBrowserWsConnection::connect - The URI supplied for the WS has an incorrect scheme - $mockBrokerAddressWsNoScheme');
      }
    });
  });

  group('Broker tests', () {
    test('Connect non-existant broker', () async {
      final client = MqttBrowserClient('ws://hhhhhhhhh/ws', testClientId);
      client.port = 10000;
      client.keepAlivePeriod = 20;
      client.logging(on: true);
      final connMess = MqttConnectMessage()
          .startClean() // Non persistent session for testing
          .withWillQos(MqttQos.atLeastOnce);
      client.connectionMessage = connMess;
      var ok = false;
      try {
        await client.connect();
      } on NoConnectionException {
        print('>>>>> TEST OK - No connection exception thrown');
        ok = true;
      }
      expect(ok, isTrue);
    }, skip: true);

    /// Local test, start the local mock WS broker found in support/mqtt_client_ws_broker
    /// locally before running this test.
    test('Connect local mock brocker', () async {
      var callbackOk = false;
      void connectCallback() {
        print('Browser client connected callback');
        callbackOk = true;
      }

      final client = MqttBrowserClient(localServer, testClientId);
      client.port = localPort;
      client.logging(on: true);
      client.keepAlivePeriod = 20;
      final connMess = MqttConnectMessage()
          .startClean() // Non persistent session for testing
          .withWillQos(MqttQos.atLeastOnce);
      client.connectionMessage = connMess;
      client.websocketProtocols = [];
      client.onConnected = connectCallback;
      var ok = true;
      try {
        await client.connect();
        var connectionOK = false;
        if (client.connectionStatus!.state == MqttConnectionState.connected) {
          print('Browser client connected locally');
          connectionOK = true;
        } else {
          print(
              'Browser client connection failed - disconnecting, status is ${client.connectionStatus}');
          client.disconnect();
        }
        expect(connectionOK, isTrue);
        expect(callbackOk, isTrue);
      } on NoConnectionException {
        print(
            '>>>>> TEST NOT OK - No connection exception thrown, is the local WS broker running?');
        ok = false;
      }
      expect(ok, isTrue);
    });
  });
}
