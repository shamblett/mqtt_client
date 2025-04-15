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

  group('Auto Reconnect', () {
    test('Connected - User Requested - Not Forced', () async {
      await IOOverrides.runZoned(
        () async {
          var autoReconnectCallbackCalled = false;
          var disconnectCallbackCalled = false;

          void autoReconnect() {
            autoReconnectCallbackCalled = true;
          }

          void disconnect() {
            disconnectCallbackCalled = true;
          }

          final client = MqttServerClient('localhost', testClientId);
          client.logging(on: false);
          client.autoReconnect = true;
          client.onAutoReconnect = autoReconnect;
          client.onDisconnected = disconnect;
          const username = 'unused 1';
          print(username);
          const password = 'password 1';
          print(password);
          await client.connect();
          expect(
            client.connectionStatus!.state == MqttConnectionState.connected,
            isTrue,
          );
          await MqttUtilities.asyncSleep(2);
          client.doAutoReconnect();
          await MqttUtilities.asyncSleep(2);
          expect(autoReconnectCallbackCalled, isFalse);
          expect(disconnectCallbackCalled, isFalse);
          expect(
            client.connectionStatus!.state == MqttConnectionState.connected,
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
            }) => MqttMockSocketSimpleConnect.connect(
              host,
              port,
              sourceAddress: sourceAddress,
              sourcePort: sourcePort,
              timeout: timeout,
            ),
      );
    });

    test('Connected - User Requested - Forced', () async {
      await IOOverrides.runZoned(
        () async {
          var autoReconnectCallbackCalled = false;
          var disconnectCallbackCalled = false;

          void autoReconnect() {
            autoReconnectCallbackCalled = true;
          }

          void disconnect() {
            disconnectCallbackCalled = true;
          }

          final client = MqttServerClient('localhost', testClientId);
          client.logging(on: false);
          client.autoReconnect = true;
          client.onAutoReconnect = autoReconnect;
          client.onDisconnected = disconnect;
          const username = 'unused 1';
          print(username);
          const password = 'password 1';
          print(password);
          await client.connect();
          expect(
            client.connectionStatus!.state == MqttConnectionState.connected,
            isTrue,
          );
          await MqttUtilities.asyncSleep(2);
          client.doAutoReconnect(force: true);
          await MqttUtilities.asyncSleep(2);
          expect(autoReconnectCallbackCalled, isTrue);
          expect(disconnectCallbackCalled, isFalse);
          expect(
            client.connectionStatus!.state == MqttConnectionState.connected,
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
            }) => MqttMockSocketSimpleConnect.connect(
              host,
              port,
              sourceAddress: sourceAddress,
              sourcePort: sourcePort,
              timeout: timeout,
            ),
      );
    });

    test('Connected - Broker Disconnects Remains Active', () async {
      await IOOverrides.runZoned(
        () async {
          var autoReconnectCallbackCalled = false;
          var disconnectCallbackCalled = false;

          void autoReconnect() {
            autoReconnectCallbackCalled = true;
          }

          void disconnect() {
            disconnectCallbackCalled = true;
          }

          final client = MqttServerClient('localhost', testClientId);
          client.logging(on: false);
          client.autoReconnect = true;
          client.keepAlivePeriod = 1;
          client.onAutoReconnect = autoReconnect;
          client.onDisconnected = disconnect;
          const username = 'unused 3';
          print(username);
          const password = 'password 3';
          print(password);
          await client.connect();
          expect(
            client.connectionStatus!.state == MqttConnectionState.connected,
            isTrue,
          );
          await MqttUtilities.asyncSleep(2);
          expect(autoReconnectCallbackCalled, isTrue);
          expect(disconnectCallbackCalled, isFalse);
          expect(
            client.connectionStatus!.state == MqttConnectionState.connected,
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
            }) => MqttMockSocketScenario2.connect(
              host,
              port,
              sourceAddress: sourceAddress,
              sourcePort: sourcePort,
              timeout: timeout,
            ),
      );
    });
  });
}
