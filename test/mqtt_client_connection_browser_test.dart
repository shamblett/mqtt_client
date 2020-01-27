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
  const mosquittoServer = 'ws://127.0.0.1/ws';
  const mosquittoPort = 8090;

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
            'MqttBrowserWsConnection::The URI supplied for the WS connection is not valid - ://localhost.com');
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
            'MqttBrowserWsConnection::The URI supplied for the WS has an incorrect scheme - $mockBrokerAddressWsNoScheme');
      }
    });
  }, skip: true);

  group('Mosquitto live tests', () {
    test('Connect', () async {
      final client = MqttBrowserClient(mosquittoServer, testClientId);
      client.port = mosquittoPort;
      client.logging(on: true);
      final connMess = MqttConnectMessage()
          .keepAliveFor(20)
          .startClean() // Non persistent session for testing
          .withWillQos(MqttQos.atLeastOnce);
      client.connectionMessage = connMess;
      await client.connect();
      var connectionOK = false;
      if (client.connectionStatus.state == MqttConnectionState.connected) {
        print('Mosquitto client connected');
        connectionOK = true;
        print('Mosquitto client connection failed OK');
      } else {
        print(
            'ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
        client.disconnect();
      }
      if (connectionOK) {
        await MqttUtilities.asyncSleep(70);
        client.disconnect();
      }
    });
  });
}
