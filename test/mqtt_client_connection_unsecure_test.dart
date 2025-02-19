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
import 'package:mocktail/mocktail.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'package:event_bus/event_bus.dart' as events;
import 'support/mqtt_client_mock_socket.dart';

// Mock classes
class MockCH extends Mock implements MqttServerConnectionHandler {
  @override
  MqttClientConnectionStatus connectionStatus = MqttClientConnectionStatus();
}

class MockKA extends Mock implements MqttConnectionKeepAlive {
  MockKA(IMqttConnectionHandler connectionHandler,
      events.EventBus? clientEventBus, int keepAliveSeconds) {
    ka = MqttConnectionKeepAlive(
        connectionHandler, clientEventBus, keepAliveSeconds);
  }

  late MqttConnectionKeepAlive ka;
}

void main() {
  // Test wide variables
  const mockBrokerAddress = 'localhost';
  const mockBrokerPort = 1883;
  const testClientId = 'syncMqttTests';
  const nonExistantHostName = 'aabbccddeeffeeddccbbaa.aa.bb';
  const badPort = 1884;
  List<RawSocketOption> socketOptions = <RawSocketOption>[];

  group('Synchronous MqttConnectionHandler', () {
    test('Connect to bad host name', () async {
      await IOOverrides.runZoned(() async {
        final clientEventBus = events.EventBus();
        final ch = SynchronousMqttServerConnectionHandler(clientEventBus,
            maxConnectionAttempts: 3,
            socketOptions: socketOptions,
            socketTimeout: null);
        try {
          await ch.connect(nonExistantHostName, mockBrokerPort,
              MqttConnectMessage().withClientIdentifier(testClientId));
        } on Exception catch (e) {
          expect(e.toString().contains('Failed host lookup'), isTrue);
          expect(e.toString().contains(nonExistantHostName), isTrue);
        }
        expect(ch.connectionStatus.state, MqttConnectionState.faulted);
        expect(ch.connectionStatus.returnCode,
            MqttConnectReturnCode.noneSpecified);
      },
          socketConnect: (dynamic host, int port,
                  {dynamic sourceAddress,
                  int sourcePort = 0,
                  Duration? timeout}) =>
              MqttMockSocketInvalidHost.connect(host, port,
                  sourceAddress: sourceAddress,
                  sourcePort: sourcePort,
                  timeout: timeout));
    });

    test('Connect invalid port', () async {
      await IOOverrides.runZoned(() async {
        final clientEventBus = events.EventBus();
        final ch = SynchronousMqttServerConnectionHandler(clientEventBus,
            maxConnectionAttempts: 3,
            socketOptions: socketOptions,
            socketTimeout: null);
        try {
          await ch.connect(mockBrokerAddress, badPort,
              MqttConnectMessage().withClientIdentifier(testClientId));
        } on Exception catch (e) {
          expect(e.toString().contains('refused'), isTrue);
        }
        expect(ch.connectionStatus.state, MqttConnectionState.faulted);
        expect(ch.connectionStatus.returnCode,
            MqttConnectReturnCode.noneSpecified);
      },
          socketConnect: (dynamic host, int port,
                  {dynamic sourceAddress,
                  int sourcePort = 0,
                  Duration? timeout}) =>
              MqttMockSocketInvalidPort.connect(host, port,
                  sourceAddress: sourceAddress,
                  sourcePort: sourcePort,
                  timeout: timeout));
    });

    test('Connect no connect ack', () async {
      await IOOverrides.runZoned(() async {
        final clientEventBus = events.EventBus();
        final ch = SynchronousMqttServerConnectionHandler(clientEventBus,
            maxConnectionAttempts: 3,
            socketOptions: socketOptions,
            socketTimeout: null);
        final start = DateTime.now();
        try {
          await ch.connect(mockBrokerAddress, mockBrokerPort,
              MqttConnectMessage().withClientIdentifier(testClientId));
        } on Exception catch (e) {
          expect(e is NoConnectionException, isTrue);
        }
        expect(ch.connectionStatus.state, MqttConnectionState.faulted);
        expect(ch.connectionStatus.returnCode,
            MqttConnectReturnCode.noneSpecified);
        final end = DateTime.now();
        expect(end.difference(start).inSeconds > 4, true);
      },
          socketConnect: (dynamic host, int port,
                  {dynamic sourceAddress,
                  int sourcePort = 0,
                  Duration? timeout}) =>
              MqttMockSocketSimpleConnectNoAck.connect(host, port,
                  sourceAddress: sourceAddress,
                  sourcePort: sourcePort,
                  timeout: timeout));
    });

    test('Connect no connect ack onFailedConnectionAttempt callback set',
        () async {
      await IOOverrides.runZoned(() async {
        bool connectionFailed = false;
        int tAttempt = 0;
        final lAttempt = <int>[];
        void onFailedConnectionAttempt(int attempt) {
          tAttempt++;
          lAttempt.add(attempt);
          connectionFailed = true;
        }

        final clientEventBus = events.EventBus();
        final ch = SynchronousMqttServerConnectionHandler(clientEventBus,
            maxConnectionAttempts: 3,
            socketOptions: socketOptions,
            socketTimeout: null);
        ch.onFailedConnectionAttempt = onFailedConnectionAttempt;
        final start = DateTime.now();
        try {
          await ch.connect(mockBrokerAddress, mockBrokerPort,
              MqttConnectMessage().withClientIdentifier(testClientId));
        } on Exception catch (e) {
          expect(e is NoConnectionException, isTrue);
        }
        expect(connectionFailed, isTrue);
        expect(tAttempt, 3);
        expect(lAttempt, [1, 2, 3]);
        expect(ch.connectionStatus.state, MqttConnectionState.faulted);
        expect(ch.connectionStatus.returnCode,
            MqttConnectReturnCode.noneSpecified);
        final end = DateTime.now();
        expect(end.difference(start).inSeconds > 4, true);
      },
          socketConnect: (dynamic host, int port,
                  {dynamic sourceAddress,
                  int sourcePort = 0,
                  Duration? timeout}) =>
              MqttMockSocketSimpleConnectNoAck.connect(host, port,
                  sourceAddress: sourceAddress,
                  sourcePort: sourcePort,
                  timeout: timeout));
    });

    test('Connect no connect ack onFailedConnectionAttempt callback set',
        () async {
      await IOOverrides.runZoned(() async {
        bool connectionFailed = false;
        int tAttempt = 0;
        final lAttempt = <int>[];
        void onFailedConnectionAttempt(int attempt) {
          tAttempt++;
          lAttempt.add(attempt);
          connectionFailed = true;
        }

        final clientEventBus = events.EventBus();
        final ch = SynchronousMqttServerConnectionHandler(clientEventBus,
            maxConnectionAttempts: 3,
            socketOptions: socketOptions,
            socketTimeout: null);
        ch.onFailedConnectionAttempt = onFailedConnectionAttempt;
        final start = DateTime.now();
        try {
          await ch.connect(mockBrokerAddress, mockBrokerPort,
              MqttConnectMessage().withClientIdentifier(testClientId));
        } on Exception catch (e) {
          expect(e is NoConnectionException, isTrue);
        }
        expect(connectionFailed, isTrue);
        expect(tAttempt, 3);
        expect(lAttempt, [1, 2, 3]);
        expect(ch.connectionStatus.state, MqttConnectionState.faulted);
        expect(ch.connectionStatus.returnCode,
            MqttConnectReturnCode.noneSpecified);
        final end = DateTime.now();
        expect(end.difference(start).inSeconds > 4, true);
      },
          socketConnect: (dynamic host, int port,
                  {dynamic sourceAddress,
                  int sourcePort = 0,
                  Duration? timeout}) =>
              MqttMockSocketSimpleConnectNoAck.connect(host, port,
                  sourceAddress: sourceAddress,
                  sourcePort: sourcePort,
                  timeout: timeout));
    });

    test('1000ms connect period', () async {
      await IOOverrides.runZoned(() async {
        final clientEventBus = events.EventBus();
        final ch = SynchronousMqttServerConnectionHandler(clientEventBus,
            maxConnectionAttempts: 3,
            reconnectTimePeriod: 1000,
            socketOptions: socketOptions,
            socketTimeout: null);

        final start = DateTime.now();

        try {
          await ch.connect(mockBrokerAddress, mockBrokerPort,
              MqttConnectMessage().withClientIdentifier(testClientId));
        } on Exception catch (e) {
          expect(e is NoConnectionException, isTrue);
        }
        expect(ch.connectionStatus.state, MqttConnectionState.faulted);
        expect(ch.connectionStatus.returnCode,
            MqttConnectReturnCode.noneSpecified);
        final end = DateTime.now();
        expect(end.difference(start).inSeconds < 4, true);
      },
          socketConnect: (dynamic host, int port,
                  {dynamic sourceAddress,
                  int sourcePort = 0,
                  Duration? timeout}) =>
              MqttMockSocketSimpleConnectNoAck.connect(host, port,
                  sourceAddress: sourceAddress,
                  sourcePort: sourcePort,
                  timeout: timeout));
    });

    test('Successful response and disconnect', () async {
      await IOOverrides.runZoned(() async {
        var connectCbCalled = false;
        void connectCb() {
          connectCbCalled = true;
        }

        final clientEventBus = events.EventBus();
        final ch = SynchronousMqttServerConnectionHandler(clientEventBus,
            maxConnectionAttempts: 3,
            socketOptions: socketOptions,
            socketTimeout: null);
        ch.onConnected = connectCb;
        final status = await ch.connect(mockBrokerAddress, mockBrokerPort,
            MqttConnectMessage().withClientIdentifier(testClientId));
        expect(ch.connectionStatus.state, MqttConnectionState.connected);
        expect(ch.connectionStatus.returnCode,
            MqttConnectReturnCode.connectionAccepted);
        expect(ch.connectionStatus.connectAckMessage, isNotNull);
        expect(
            status.connectAckMessage?.variableHeader.sessionPresent, isFalse);
        expect(connectCbCalled, isTrue);
        final state = ch.disconnect();
        expect(state, MqttConnectionState.disconnected);
      },
          socketConnect: (dynamic host, int port,
                  {dynamic sourceAddress,
                  int sourcePort = 0,
                  Duration? timeout}) =>
              MqttMockSocketSimpleConnect.connect(host, port,
                  sourceAddress: sourceAddress,
                  sourcePort: sourcePort,
                  timeout: timeout));
    });

    test('Successful response and disconnect with session present', () async {
      await IOOverrides.runZoned(() async {
        Protocol.version = MqttClientConstants.mqttV311ProtocolVersion;
        final clientEventBus = events.EventBus();
        final ch = SynchronousMqttServerConnectionHandler(clientEventBus,
            maxConnectionAttempts: 3,
            socketOptions: socketOptions,
            socketTimeout: null);
        final status = await ch.connect(mockBrokerAddress, mockBrokerPort,
            MqttConnectMessage().withClientIdentifier(testClientId));
        expect(status.state, MqttConnectionState.connected);
        expect(status.returnCode, MqttConnectReturnCode.connectionAccepted);
        expect(status.connectAckMessage, isNotNull);
        expect(status.connectAckMessage?.variableHeader.sessionPresent, isTrue);
        final state = ch.disconnect();
        expect(state, MqttConnectionState.disconnected);
      },
          socketConnect: (dynamic host, int port,
                  {dynamic sourceAddress,
                  int sourcePort = 0,
                  Duration? timeout}) =>
              MqttMockSocketSimpleConnect.connect(host, port,
                  sourceAddress: sourceAddress,
                  sourcePort: sourcePort,
                  timeout: timeout));
    });
  });

  group('Connection Keep Alive - Mock broker', () {
    test('Successful response', () async {
      await IOOverrides.runZoned(() async {
        final clientEventBus = events.EventBus();
        final ch = SynchronousMqttServerConnectionHandler(clientEventBus,
            maxConnectionAttempts: 3,
            socketOptions: socketOptions,
            socketTimeout: null);
        await ch.connect(mockBrokerAddress, mockBrokerPort,
            MqttConnectMessage().withClientIdentifier(testClientId));
        expect(ch.connectionStatus.state, MqttConnectionState.connected);
        expect(ch.connectionStatus.returnCode,
            MqttConnectReturnCode.connectionAccepted);
        final ka = MqttConnectionKeepAlive(ch, clientEventBus, 2);
        print(
            'Connection Keep Alive - Successful response - keep alive ms is ${ka.keepAlivePeriod}');
        print(
            'Connection Keep Alive - Successful response - ping timer active is ${ka.pingTimer!.isActive.toString()}');
        final stopwatch = Stopwatch()..start();
        await MqttUtilities.asyncSleep(10);
        print('Connection Keep Alive - Successful response - Elapsed time '
            'is ${stopwatch.elapsedMilliseconds / 1000} seconds');
        ka.stop();
      },
          socketConnect: (dynamic host, int port,
                  {dynamic sourceAddress,
                  int sourcePort = 0,
                  Duration? timeout}) =>
              MqttMockSocketScenario3.connect(host, port,
                  sourceAddress: sourceAddress,
                  sourcePort: sourcePort,
                  timeout: timeout));
    });
  });

  group('Client interface', () {
    test('Normal publish', () async {
      await IOOverrides.runZoned(() async {
        final client = MqttServerClient('localhost', 'SJHMQTTClient');
        client.logging(on: true);
        const username = 'unused';
        print(username);
        const password = 'password';
        print(password);
        await client.connect();
        if (client.connectionStatus!.state == MqttConnectionState.connected) {
          print('Client connected');
        } else {
          print(
              'ERROR Client connection failed - disconnecting, state is ${client.connectionStatus!.state}');
          client.disconnect();
        }
        // Publish a known topic
        const topic = 'Dart/SJH/mqtt_client';
        final buff = typed.Uint8Buffer(5);
        buff[0] = 'h'.codeUnitAt(0);
        buff[1] = 'e'.codeUnitAt(0);
        buff[2] = 'l'.codeUnitAt(0);
        buff[3] = 'l'.codeUnitAt(0);
        buff[4] = 'o'.codeUnitAt(0);
        client.publishMessage(topic, MqttQos.exactlyOnce, buff);
        // Manual acknowledge count should be 0
        expect(client.messagesAwaitingManualAcknowledge, 0);
        print('Sleeping....');
        await MqttUtilities.asyncSleep(2);
        print('Disconnecting');
        client.disconnect();
        expect(
            client.connectionStatus!.state, MqttConnectionState.disconnected);
      },
          socketConnect: (dynamic host, int port,
                  {dynamic sourceAddress,
                  int sourcePort = 0,
                  Duration? timeout}) =>
              MqttMockSocketSimpleConnect.connect(host, port,
                  sourceAddress: sourceAddress,
                  sourcePort: sourcePort,
                  timeout: timeout));
    });
  });
}
