/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 02/10/2017
 * Copyright :  S.Hamblett
 */

@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'package:path/path.dart' as path;
import 'package:event_bus/event_bus.dart' as events;
import 'support/mqtt_client_mockbroker.dart';

// Mock classes
class MockCH extends Mock implements MqttServerConnectionHandler {
  @override
  MqttClientConnectionStatus connectionStatus = MqttClientConnectionStatus();
}

class MockKA extends Mock implements MqttConnectionKeepAlive {
  MockKA(
    IMqttConnectionHandler connectionHandler,
    MqttEventBus clientEventBus,
    int keepAliveSeconds,
  ) {
    ka = MqttConnectionKeepAlive(
      connectionHandler,
      clientEventBus,
      keepAliveSeconds,
    );
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
        final ack = MqttConnectAckMessage().withReturnCode(
          MqttConnectReturnCode.connectionAccepted,
        );
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
            'Connection Keep Alive - Successful response - Ping Request received $expectRequest',
          );
          expect(header.messageType, MqttMessageType.pingRequest);
          expectRequest++;
        }
      }

      await broker.start();
      final clientEventBus = MqttEventBus.fromEventBus(events.EventBus());
      final ch = SynchronousMqttServerConnectionHandler(
        clientEventBus,
        maxConnectionAttempts: 3,
        socketOptions: socketOptions,
        socketTimeout: null,
      );
      ch.secure = true;
      final context = SecurityContext.defaultContext;
      final currDir = path.current + path.separator;
      context.setTrustedCertificates(
        currDir + path.join('test', 'pem', 'localhost.cert'),
      );
      ch.securityContext = context;
      await ch.connect(
        mockBrokerAddress,
        mockBrokerPort,
        MqttConnectMessage().withClientIdentifier(testClientId),
      );
      expect(ch.connectionStatus.state, MqttConnectionState.connected);
      broker.setMessageHandler = messageHandlerPingRequest;
      final ka = MqttConnectionKeepAlive(ch, clientEventBus, 2);
      print(
        'Connection Keep Alive - Successful response - keep alive ms is ${ka.keepAlivePeriod}',
      );
      print(
        'Connection Keep Alive - Successful response - ping timer active is ${ka.pingTimer!.isActive.toString()}',
      );
      final stopwatch = Stopwatch()..start();
      await MqttUtilities.asyncSleep(10);
      print(
        'Connection Keep Alive - Successful response - Elapsed time '
        'is ${stopwatch.elapsedMilliseconds / 1000} seconds',
      );
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
        final clientEventBus = MqttEventBus.fromEventBus(events.EventBus());
        final ch = SynchronousMqttServerConnectionHandler(
          clientEventBus,
          maxConnectionAttempts: 3,
          socketOptions: socketOptions,
          socketTimeout: null,
        );
        ch.secure = true;
        ch.onDisconnected = disconnectCB;
        final context = SecurityContext();
        final currDir = path.current + path.separator;
        context.setTrustedCertificates(
          currDir + path.join('test', 'pem', 'self_signed.cert'),
        );
        ch.securityContext = context;
        try {
          await ch.connect(
            mockBrokerAddress,
            mockBrokerPort,
            MqttConnectMessage().withClientIdentifier(testClientId),
          );
        } on Exception catch (e) {
          expect(e.toString().contains('Handshake error in client'), isTrue);
        }
        expect(ch.connectionStatus.state, MqttConnectionState.faulted);
        expect(cbCalled, isTrue);
      },
    );
    test(
      'Successfully connected to broker with self-signed certifcate',
      () async {
        broker.pemName = 'self_signed';
        await broker.start();
        final clientEventBus = MqttEventBus.fromEventBus(events.EventBus());
        final ch = SynchronousMqttServerConnectionHandler(
          clientEventBus,
          maxConnectionAttempts: 3,
          socketOptions: socketOptions,
          socketTimeout: null,
        );
        ch.secure = true;
        // Skip bad certificate
        ch.onBadCertificate = (_) => true;
        final context = SecurityContext();
        final currDir = path.current + path.separator;
        context.setTrustedCertificates(
          currDir + path.join('test', 'pem', 'self_signed.cert'),
        );
        ch.securityContext = context;
        await ch.connect(
          mockBrokerAddress,
          mockBrokerPort,
          MqttConnectMessage().withClientIdentifier(testClientId),
        );
        expect(ch.connectionStatus.state, MqttConnectionState.connected);
        ch.close();
      },
    );
  });

  group('Connection Timeout', () {
    test('TLS handshake never answered', () async {
      // Accepts the TCP connection, never answers the TLS client hello
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final accepted = <Socket>[];
      server.listen(accepted.add);
      final client = MqttServerClient.withPort(
        InternetAddress.loopbackIPv4.address,
        testClientId,
        server.port,
        maxConnectionAttempts: 1,
      );
      client.logging(on: false);
      client.secure = true;
      client.securityContext = SecurityContext();
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
      expect(stopwatch.elapsedMilliseconds, lessThan(4000));
      // The TCP connection was made, the handshake was not answered
      expect(accepted, hasLength(1));
      expect(client.connectionStatus!.state, MqttConnectionState.faulted);
      for (final socket in accepted) {
        socket.destroy();
      }
      await server.close();
    });

    test('TLS handshake completed after the timeout is never used', () async {
      final context = SecurityContext();
      final currDir = path.current + path.separator;
      context.useCertificateChain(
        currDir + path.join('test', 'pem', 'self_signed.cert'),
      );
      context.usePrivateKey(
        currDir + path.join('test', 'pem', 'self_signed.key'),
      );
      final received = <int>[];
      final closed = Completer<void>();
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((socket) async {
        // Answer the TLS handshake only after the connection timeout
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        try {
          final secureSocket = await SecureSocket.secureServer(socket, context);
          secureSocket.listen(
            received.addAll,
            onDone: closed.complete,
            onError: (_) => closed.complete(),
          );
        } on Exception {
          // Closed by the client during the last handshake flight
          closed.complete();
        }
      });
      final client = MqttServerClient.withPort(
        InternetAddress.loopbackIPv4.address,
        testClientId,
        server.port,
        maxConnectionAttempts: 1,
      );
      client.logging(on: false);
      client.secure = true;
      client.securityContext = SecurityContext();
      client.onBadCertificate = (Object certificate) => true;
      client.connectionTimeout = 500;
      await expectLater(
        client.connect(),
        throwsA(isA<NoConnectionException>()),
      );
      // The late socket is destroyed by the client, it sends nothing
      await closed.future.timeout(const Duration(seconds: 5));
      expect(received, isEmpty);
      await server.close();
    });

    test('Connects to a broker within the timeout', () async {
      final broker = MockBrokerSecure();
      broker.pemName = 'self_signed';
      broker.setMessageHandler = (typed.Uint8Buffer? messageArrived) {
        broker.sendMessage(
          MqttConnectAckMessage().withReturnCode(
            MqttConnectReturnCode.connectionAccepted,
          ),
        );
      };
      await broker.start();
      final client = MqttServerClient.withPort(
        mockBrokerAddress,
        testClientId,
        mockBrokerPort,
        maxConnectionAttempts: 1,
      );
      client.logging(on: false);
      client.secure = true;
      client.securityContext = SecurityContext();
      client.onBadCertificate = (Object certificate) => true;
      client.connectionTimeout = 5000;
      final status = await client.connect();
      expect(status!.state, MqttConnectionState.connected);
      client.disconnect();
      broker.close();
    });
  });
}
