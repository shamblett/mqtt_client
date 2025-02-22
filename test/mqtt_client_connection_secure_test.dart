/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 02/10/2017
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
import 'package:path/path.dart' as path;
import 'package:event_bus/event_bus.dart' as events;
import 'support/mqtt_client_mockbroker.dart';
import 'support/mqtt_client_mock_socket.dart';

// Mock classes
class MockCH extends Mock implements MqttServerConnectionHandler {
  @override
  MqttClientConnectionStatus connectionStatus = MqttClientConnectionStatus();
}

class MockKA extends Mock implements MqttConnectionKeepAlive {
  MockKA(IMqttConnectionHandler connectionHandler,
      events.EventBus clientEventBus, int keepAliveSeconds) {
    ka = MqttConnectionKeepAlive(
        connectionHandler, clientEventBus, keepAliveSeconds);
  }

  late MqttConnectionKeepAlive ka;
}

void main() {
  // Test wide variables
  const mockBrokerAddress = 'localhost';
  const mockBrokerPort = 8883;
  const testClientId = 'syncMqttTests';
  List<RawSocketOption> socketOptions = <RawSocketOption>[];

  group('MockBroker', () {
    late MockBrokerSecure broker;

    setUp(() async {
      broker = MockBrokerSecure();
      broker.pemName = 'localhost';
      void messageHandlerConnect(typed.Uint8Buffer? messageArrived) {
        final ack = MqttConnectAckMessage()
            .withReturnCode(MqttConnectReturnCode.connectionAccepted);
        broker.sendMessage(ack);
      }

      broker.setMessageHandler = messageHandlerConnect;
    });

    tearDown(() {
      broker.close();
    });

    test('Connection Keep Alive - Successful response', () async {
      var expectRequest = 0;

      void messageHandlerPingRequest(typed.Uint8Buffer? messageArrived) {
        final headerStream = MqttByteBuffer(messageArrived);
        final header = MqttHeader.fromByteBuffer(headerStream);
        if (expectRequest <= 3) {
          print(
              'Connection Keep Alive - Successful response - Ping Request received $expectRequest');
          expect(header.messageType, MqttMessageType.pingRequest);
          expectRequest++;
        }
      }

      await broker.start();
      final clientEventBus = events.EventBus();
      final ch = SynchronousMqttServerConnectionHandler(clientEventBus,
          maxConnectionAttempts: 3,
          socketOptions: socketOptions,
          socketTimeout: null);
      ch.secure = true;
      final context = SecurityContext.defaultContext;
      final currDir = path.current + path.separator;
      context.setTrustedCertificates(
          currDir + path.join('test', 'pem', 'localhost.cert'));
      ch.securityContext = context;
      await ch.connect(mockBrokerAddress, mockBrokerPort,
          MqttConnectMessage().withClientIdentifier(testClientId));
      expect(ch.connectionStatus.state, MqttConnectionState.connected);
      broker.setMessageHandler = messageHandlerPingRequest;
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
      ch.close();
    });

    test(
        'Self-signed certificate - Failed with error - Handshake error in client',
        () async {
      var cbCalled = false;
      void disconnectCB() {
        cbCalled = true;
      }

      broker.pemName = 'self_signed';
      await broker.start();
      final clientEventBus = events.EventBus();
      final ch = SynchronousMqttServerConnectionHandler(clientEventBus,
          maxConnectionAttempts: 3,
          socketOptions: socketOptions,
          socketTimeout: null);
      ch.secure = true;
      ch.onDisconnected = disconnectCB;
      final context = SecurityContext();
      final currDir = path.current + path.separator;
      context.setTrustedCertificates(
          currDir + path.join('test', 'pem', 'self_signed.cert'));
      ch.securityContext = context;
      try {
        await ch.connect(mockBrokerAddress, mockBrokerPort,
            MqttConnectMessage().withClientIdentifier(testClientId));
      } on Exception catch (e) {
        expect(e.toString().contains('Handshake error in client'), isTrue);
      }
      expect(ch.connectionStatus.state, MqttConnectionState.faulted);
      expect(cbCalled, isTrue);
    });
    test('Successfully connected to broker with self-signed certifcate',
        () async {
      broker.pemName = 'self_signed';
      await broker.start();
      final clientEventBus = events.EventBus();
      final ch = SynchronousMqttServerConnectionHandler(clientEventBus,
          maxConnectionAttempts: 3,
          socketOptions: socketOptions,
          socketTimeout: null);
      ch.secure = true;
      // Skip bad certificate
      ch.onBadCertificate = (_) => true;
      final context = SecurityContext();
      final currDir = path.current + path.separator;
      context.setTrustedCertificates(
          currDir + path.join('test', 'pem', 'self_signed.cert'));
      ch.securityContext = context;
      await ch.connect(mockBrokerAddress, mockBrokerPort,
          MqttConnectMessage().withClientIdentifier(testClientId));
      expect(ch.connectionStatus.state, MqttConnectionState.connected);
      ch.close();
    });
    test('Socket Timeout', () async {
      await IOOverrides.runZoned(() async {
        bool testOk = false;
        final client =
            MqttServerClient('localhost', '', maxConnectionAttempts: 1);
        final start = DateTime.now();
        client.socketTimeout = 500;
        expect(client.socketTimeout, isNull);
        expect(client.connectTimeoutPeriod, 5000);
        client.socketTimeout = 2000;
        expect(client.connectTimeoutPeriod, 10);
        client.connectTimeoutPeriod = 5000;
        expect(client.connectTimeoutPeriod, 10);
        try {
          await client.connect();
        } on NoConnectionException {
          testOk = true;
        }
        final end = DateTime.now();
        expect(end.isAfter(start), isTrue);
        expect(end.subtract(Duration(seconds: 2)).second, start.second);
        expect(testOk, isTrue);
      },
          socketConnect: (dynamic host, int port,
                  {dynamic sourceAddress,
                  int sourcePort = 0,
                  Duration? timeout}) =>
              MqttMockSecureSocketTimeout.connect(host, port,
                  sourceAddress: sourceAddress,
                  sourcePort: sourcePort,
                  timeout: timeout));
    });
  });
}
