/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/03/2020
 * Copyright :  S.Hamblett
 */

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'support/mqtt_client_mockbroker.dart';

@TestOn('vm')
void main() {
  // Test wide variables
  final broker = MockBroker();
  const mockBrokerAddress = 'localhost';
  const testClientId = 'SJHMQTTClient';

  group('Auto Reconnect', () {
    test('Connected - User Requested - Not Forced', () async {
      var autoReconnectCallbackCalled = false;
      var disconnectCallbackCalled = false;

      void messageHandlerConnect(typed.Uint8Buffer messageArrived) {
        final ack = MqttConnectAckMessage()
            .withReturnCode(MqttConnectReturnCode.connectionAccepted);
        broker.sendMessage(ack);
      }

      void autoReconnect() {
        autoReconnectCallbackCalled = true;
      }

      void disconnect() {
        disconnectCallbackCalled = true;
      }

      broker.setMessageHandler = messageHandlerConnect;
      await broker.start();
      final client = MqttServerClient(mockBrokerAddress, testClientId);
      client.logging(on: true);
      client.autoReconnect = true;
      client.onAutoReconnect = autoReconnect;
      client.onDisconnected = disconnect;
      const username = 'unused';
      print(username);
      const password = 'password';
      print(password);
      await client.connect();
      expect(client.connectionStatus.state == MqttConnectionState.connected,
          isTrue);
      await MqttUtilities.asyncSleep(2);
      client.doAutoReconnect();
      await MqttUtilities.asyncSleep(2);
      expect(autoReconnectCallbackCalled, isFalse);
      expect(disconnectCallbackCalled, isFalse);
      expect(client.connectionStatus.state == MqttConnectionState.connected,
          isTrue);
      broker.close();
    });

    test('Connected - User Requested - Forced', () async {
      var autoReconnectCallbackCalled = false;
      var disconnectCallbackCalled = false;

      void messageHandlerConnect(typed.Uint8Buffer messageArrived) {
        final ack = MqttConnectAckMessage()
            .withReturnCode(MqttConnectReturnCode.connectionAccepted);
        broker.sendMessage(ack);
      }

      void autoReconnect() {
        autoReconnectCallbackCalled = true;
      }

      void disconnect() {
        disconnectCallbackCalled = true;
      }

      broker.setMessageHandler = messageHandlerConnect;
      await broker.start();
      final client = MqttServerClient(mockBrokerAddress, testClientId);
      client.logging(on: true);
      client.autoReconnect = true;
      client.onAutoReconnect = autoReconnect;
      client.onDisconnected = disconnect;
      const username = 'unused';
      print(username);
      const password = 'password';
      print(password);
      await client.connect();
      expect(client.connectionStatus.state == MqttConnectionState.connected,
          isTrue);
      broker.close();
      await MqttUtilities.asyncSleep(2);
      client.doAutoReconnect();
      await MqttUtilities.asyncSleep(2);
      expect(autoReconnectCallbackCalled, isTrue);
      expect(disconnectCallbackCalled, isFalse);
      expect(client.connectionStatus.state == MqttConnectionState.connected,
          isTrue);
    });
  });
}
