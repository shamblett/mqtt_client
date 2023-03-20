/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/03/2020
 * Copyright :  S.Hamblett
 */

@TestOn('vm')
import 'dart:io';
import 'dart:async';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'support/mqtt_client_mock_socket.dart';

void main() {
  // Test wide variables
  const testClientId = 'SJHMQTTClient';

  test('Connected - Broker Disconnects Stays Inactive', () async {


    await IOOverrides.runZoned(() async {
      var autoReconnectCallbackCalled = false;
      var disconnectCallbackCalled = false;

      void autoReconnect() {
        autoReconnectCallbackCalled = true;
      }

      void disconnect() {
        disconnectCallbackCalled = true;
      }
      final client = MqttServerClient('localhost', testClientId);
      client.logging(on: true);
      client.keepAlivePeriod = 1;
      client.autoReconnect = true;
      client.onAutoReconnect = autoReconnect;
      client.onDisconnected = disconnect;
      const username = 'unused 4';
      print(username);
      const password = 'password 4';
      print(password);
      await client.connect();
      expect(client.connectionStatus!.state == MqttConnectionState.connected,
          isTrue);
      await MqttUtilities.asyncSleep(2);
      expect(autoReconnectCallbackCalled, isTrue);
      expect(disconnectCallbackCalled, isFalse);
      expect(client.connectionStatus!.state == MqttConnectionState.connecting,
          isTrue);
    },
        socketConnect: (dynamic host, int port,
                {dynamic sourceAddress,
                int sourcePort = 0,
                Duration? timeout}) =>
            MqttSimpleConnectWithDisconnect.connect(host, port,
                sourceAddress: sourceAddress,
                sourcePort: sourcePort,
                timeout: timeout));
  });

  test('Connected - Broker Disconnects Stays Inactive - with socket options',
      () async {
    void messageHandlerConnect(typed.Uint8Buffer? messageArrived) {
      final ack = MqttConnectAckMessage()
          .withReturnCode(MqttConnectReturnCode.connectionAccepted);
      //broker.sendMessage(ack);
    }

    //broker.setMessageHandler = messageHandlerConnect;
    //await broker.start();
    //final client = MqttServerClient(mockBrokerAddress, testClientId);
    //client.logging(on: true);
    //client.autoReconnect = true;
    final socketOption = RawSocketOption.fromInt(6, 0x10, 2);
    //client.socketOptions.add(socketOption);
    const username = 'unused 4';
    print(username);
    const password = 'password 4';
    print(password);
    try {
      //await client.connect();
    } catch (e) {
      //expect(client.connectionStatus!.state == MqttConnectionState.connected,
      //   isFalse);
      expect(e.toString().contains('OS Error'), isTrue);
    }
    //broker.close();
  });
}
