/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/06/2017
 * Copyright :  S.Hamblett
 */

@TestOn('vm')
library;

import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'package:event_bus/event_bus.dart' as events;
import 'support/mqtt_client_mockbroker.dart';

// ignore_for_file: invalid_use_of_protected_member

void main() {
  // Test wide variables
  final brokerWs = MockBrokerWs();
  const mockBrokerAddressWs = 'ws://localhost/ws';
  const mockBrokerAddressWsNoScheme = 'localhost.com';
  const mockBrokerAddressWsBad = '://localhost.com';
  const mockBrokerPortWs = 8090;
  const testClientId = 'syncMqttTests';
  List<RawSocketOption> socketOptions = <RawSocketOption>[];

  group('Connection parameters', () {
    test('Invalid URL', () async {
      try {
        final clientEventBus = MqttEventBus.fromEventBus(events.EventBus());
        final ch = SynchronousMqttServerConnectionHandler(
          clientEventBus,
          maxConnectionAttempts: 3,
          socketOptions: socketOptions,
          socketTimeout: null,
        );
        ch.useWebSocket = true;
        await ch.connect(
          mockBrokerAddressWsBad,
          mockBrokerPortWs,
          MqttConnectMessage().withClientIdentifier(testClientId),
        );
      } on Exception catch (e) {
        expect(e is NoConnectionException, true);
        expect(
          e.toString(),
          'mqtt-client::NoConnectionException: '
          'MqttWsConnection::connect - The URI supplied for the WS connection is not valid - ://localhost.com',
        );
      }
    });

    test('Web Protocol string', () {
      var protocols = MqttClientConstants.protocolsMultipleDefault;
      expect(protocols.join(' ').trim(), 'mqtt mqttv3.1 mqttv3.11');
      protocols = MqttClientConstants.protocolsSingleDefault;
      expect(protocols.join(' ').trim(), 'mqtt');
      protocols = <String>[];
      expect(protocols.join(' ').trim(), '');
    });

    test('Invalid URL - bad scheme', () async {
      try {
        final clientEventBus = MqttEventBus.fromEventBus(events.EventBus());
        final ch = SynchronousMqttServerConnectionHandler(
          clientEventBus,
          maxConnectionAttempts: 3,
          socketOptions: socketOptions,
          socketTimeout: null,
        );
        ch.useWebSocket = true;
        await ch.connect(
          mockBrokerAddressWsNoScheme,
          mockBrokerPortWs,
          MqttConnectMessage().withClientIdentifier(testClientId),
        );
      } on Exception catch (e) {
        expect(e is NoConnectionException, true);
        expect(
          e.toString(),
          'mqtt-client::NoConnectionException: '
          'MqttWsConnection::connect - The URI supplied for the WS has an incorrect scheme - $mockBrokerAddressWsNoScheme',
        );
      }
    });
  });

  group('Connection Keep Alive - Mock broker WS', () {
    test('Successful response WS', () async {
      var expectRequest = 0;

      void messageHandlerConnect(typed.Uint8Buffer? messageArrived) {
        final ack = MqttConnectAckMessage().withReturnCode(
          MqttConnectReturnCode.connectionAccepted,
        );
        brokerWs.sendMessage(ack);
      }

      void messageHandlerPingRequest(typed.Uint8Buffer? messageArrived) {
        final headerStream = MqttByteBuffer(messageArrived);
        final header = MqttHeader.fromByteBuffer(headerStream);
        if (expectRequest <= 3) {
          print(
            'WS Connection Keep Alive - Successful response - Ping Request received $expectRequest',
          );
          expect(header.messageType, MqttMessageType.pingRequest);
          expectRequest++;
        }
      }

      await brokerWs.start();
      final clientEventBus = MqttEventBus.fromEventBus(events.EventBus());
      final ch = SynchronousMqttServerConnectionHandler(
        clientEventBus,
        maxConnectionAttempts: 3,
        socketOptions: socketOptions,
        socketTimeout: null,
      );
      MqttLogger.loggingOn = false;
      ch.useWebSocket = true;
      ch.websocketProtocols = <String>['SJHprotocol'];
      ch.websocketHeaders = {'Origin': 'SJH'};
      brokerWs.setMessageHandler = messageHandlerConnect;
      await ch.connect(
        mockBrokerAddressWs,
        mockBrokerPortWs,
        MqttConnectMessage().withClientIdentifier(testClientId),
      );
      expect(ch.connectionStatus.state, MqttConnectionState.connected);
      brokerWs.setMessageHandler = messageHandlerPingRequest;
      final ka = MqttConnectionKeepAlive(ch, clientEventBus, 2);
      print(
        'WS Connection Keep Alive - Successful response - keep alive ms is ${ka.keepAlivePeriod}',
      );
      print(
        'WS Connection Keep Alive - Successful response - ping timer active is ${ka.pingTimer!.isActive.toString()}',
      );
      final stopwatch = Stopwatch()..start();
      await MqttUtilities.asyncSleep(10);
      print(
        'WS Connection Keep Alive - Successful response - Elapsed time '
        'is ${stopwatch.elapsedMilliseconds / 1000} seconds',
      );
      ka.stop();
      ch.close();
    });
  });

  group('Connection Timeout - WS', () {
    // A broker that accepts the TCP connection but never answers the
    // websocket upgrade, as a network that has dropped behind a proxy does.
    Future<ServerSocket> silentBroker(List<Socket> held) async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      server.listen(held.add);
      return server;
    }

    test('Upgrade never answered fails at the connection timeout', () async {
      final held = <Socket>[];
      final server = await silentBroker(held);
      final client = MqttServerClient.withPort(
        'ws://127.0.0.1/mqtt',
        testClientId,
        server.port,
        maxConnectionAttempts: 1,
      );
      client.logging(on: false);
      client.useWebSocket = true;
      client.connectionTimeout = 1000;
      final stopwatch = Stopwatch()..start();
      Object? error;
      try {
        await client.connect();
      } on NoConnectionException catch (e) {
        error = e;
      }
      stopwatch.stop();
      expect(
        error.toString(),
        contains('the connection timeout of 1000ms has elapsed'),
      );
      // Failed at the connection timeout, not after the connect
      // acknowledgement wait (connectTimeoutPeriod, 5000ms).
      expect(stopwatch.elapsedMilliseconds, lessThan(4000));
      expect(client.connectionStatus!.state, MqttConnectionState.faulted);
      for (final socket in held) {
        socket.destroy();
      }
      await server.close();
    });

    test('Auto reconnect retries when an attempt is never answered', () async {
      // Each reconnect attempt hangs on the upgrade: without the timeout the
      // first one would hold the auto reconnect forever, so a second attempt
      // reaching the broker proves it moved on.
      final held = <Socket>[];
      final server = await silentBroker(held);
      final ch = SynchronousMqttServerConnectionHandler(
        MqttEventBus.fromEventBus(events.EventBus()),
        maxConnectionAttempts: 1,
        reconnectTimePeriod: 1000,
        socketOptions: socketOptions,
        socketTimeout: null,
      );
      ch.useWebSocket = true;
      ch.connectionTimeout = const Duration(milliseconds: 500);
      try {
        await ch.connect(
          'ws://127.0.0.1/mqtt',
          server.port,
          MqttConnectMessage().withClientIdentifier(testClientId),
        );
      } on NoConnectionException {
        // The first connect times out too.
      }
      final before = held.length;
      ch.autoReconnect(AutoReconnect(userRequested: true));
      await Future<void>.delayed(const Duration(seconds: 4));
      expect(held.length - before, greaterThanOrEqualTo(2));
      ch.autoReconnectInProgress = false;
      for (final socket in held) {
        socket.destroy();
      }
      await server.close();
    });
  });
}
