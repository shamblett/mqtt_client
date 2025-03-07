/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/03/2020
 * Copyright :  S.Hamblett
 */

@TestOn('vm')
library;

import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:test/test.dart';
import 'support/mqtt_client_mock_socket.dart';

void main() {
  // Test wide variables
  const testClientId = 'SJHMQTTClient';

  test('Connected - Broker Disconnects Stays Inactive', () async {
    await IOOverrides.runZoned(
      () async {
        var autoReconnectCallbackCalled = false;
        var disconnectCallbackCalled = false;
        var connectionFailedCallbackCalled = false;

        void autoReconnect() {
          autoReconnectCallbackCalled = true;
        }

        void disconnect() {
          disconnectCallbackCalled = true;
        }

        void connectionFailed(int attempt) {
          connectionFailedCallbackCalled = true;
        }

        final client = MqttServerClient('localhost', testClientId);
        client.logging(on: false);
        client.keepAlivePeriod = 1;
        client.autoReconnect = true;
        final socketOption = RawSocketOption.fromInt(6, 0x10, 2);
        client.socketOptions.add(socketOption);
        client.onAutoReconnect = autoReconnect;
        client.onDisconnected = disconnect;
        client.onFailedConnectionAttempt = connectionFailed;
        const username = 'unused 4';
        print(username);
        const password = 'password 4';
        print(password);
        await client.connect();
        expect(
          client.connectionStatus!.state == MqttConnectionState.connected,
          isTrue,
        );
        await MqttUtilities.asyncSleep(2);
        expect(autoReconnectCallbackCalled, isTrue);
        expect(disconnectCallbackCalled, isFalse);
        expect(connectionFailedCallbackCalled, isFalse);
        expect(
          client.connectionStatus!.state == MqttConnectionState.connecting,
          isTrue,
        );
      },
      socketConnect:
          (
            dynamic host,
            int port, {
            dynamic sourceAddress,
            int sourcePort = 0,
            Duration? timeout,
          }) => MqttMockSocketScenario1.connect(
            host,
            port,
            sourceAddress: sourceAddress,
            sourcePort: sourcePort,
            timeout: timeout,
          ),
    );
  });
}
