/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 02/10/2017
 * Copyright :  S.Hamblett
 */

import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'package:path/path.dart' as path;
import 'package:event_bus/event_bus.dart' as events;
import 'support/mqtt_client_mockbroker.dart';

// ignore_for_file: cascade_invocations
// ignore_for_file: unnecessary_final
// ignore_for_file: omit_local_variable_types
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: avoid_print

// Mock classes
class MockCH extends Mock implements MqttConnectionHandler {
  @override
  MqttClientConnectionStatus connectionStatus = MqttClientConnectionStatus();
}

class MockKA extends Mock implements MqttConnectionKeepAlive {
  MockKA(IMqttConnectionHandler connectionHandler, int keepAliveSeconds) {
    ka = MqttConnectionKeepAlive(connectionHandler, keepAliveSeconds);
  }

  MqttConnectionKeepAlive ka;
}

void main() {
  // Test wide variables
  const String mockBrokerAddress = 'localhost';
  const int mockBrokerPort = 8883;
  const String testClientId = 'syncMqttTests';
  const String nonExistantHostName = 'aabbccddeeffeeddccbbaa.aa.bb';
  const int badPort = 1884;

  group('Connection Keep Alive - Mock tests', () {
    // Group setup
    final MockCH ch = MockCH();
    when(ch.secure).thenReturn(true);
    final MockKA ka = MockKA(ch, 3);
    test('Message sent', () {
      final MqttMessage msg = MqttPingRequestMessage();
      when(ka.messageSent(msg)).thenReturn(ka.ka.messageSent(msg));
      expect(ka.messageSent(msg), isTrue);
      verify(ka.messageSent(msg));
    });
    test('Ping response received', () {
      final MqttMessage msg = MqttPingResponseMessage();
      when(ka.pingResponseReceived(msg))
          .thenReturn(ka.ka.pingResponseReceived(msg));
      expect(ka.pingResponseReceived(msg), isTrue);
      verify(ka.pingResponseReceived(msg));
    });
    test('Ping request received', () {
      final MqttMessage msg = MqttPingRequestMessage();
      when(ka.pingRequestReceived(msg))
          .thenReturn(ka.ka.pingRequestReceived(msg));
      expect(ka.pingRequestReceived(msg), isTrue);
      verify(ka.pingRequestReceived(msg));
    });
    test('Ping required', () {
      when(ka.pingRequired()).thenReturn(ka.ka.pingRequired());
      expect(ka.pingRequired(), false);
      verify(ka.pingRequired());
      expect(ka.ka.pingTimer, isNotNull);
      expect(ka.ka.pingTimer.isActive, isTrue);
      ka.ka.pingTimer.cancel();
    });
  }, skip: false);

  group('Synchronous MqttConnectionHandler', () {
    test('Connect to bad host name', () async {
      final events.EventBus clientEventBus = events.EventBus();
      final SynchronousMqttConnectionHandler ch =
          SynchronousMqttConnectionHandler(clientEventBus);
      ch.secure = true;
      try {
        await ch.connect(nonExistantHostName, mockBrokerPort,
            MqttConnectMessage().withClientIdentifier(testClientId));
      } on Exception catch (e) {
        expect(e.toString().contains('Failed host lookup'), isTrue);
        expect(e.toString().contains(nonExistantHostName), isTrue);
      }
      expect(ch.connectionStatus.state, MqttConnectionState.faulted);
    }, skip: true);
    test('Connect invalid port', () async {
      bool cbCalled = false;
      void disconnectCB() {
        cbCalled = true;
      }

      final events.EventBus clientEventBus = events.EventBus();
      final SynchronousMqttConnectionHandler ch =
          SynchronousMqttConnectionHandler(clientEventBus);
      ch.secure = true;
      ch.onDisconnected = disconnectCB;
      try {
        await ch.connect(mockBrokerAddress, badPort,
            MqttConnectMessage().withClientIdentifier(testClientId));
      } on Exception catch (e) {
        expect(e.toString().contains('refused'), isTrue);
      }
      expect(ch.connectionStatus.state, MqttConnectionState.faulted);
      expect(cbCalled, isTrue);
    });
  });

  group('MockBroker', () {
    MockBrokerSecure broker;

    setUp(() async {
      broker = MockBrokerSecure();
      broker.pemName = 'localhost';
      void messageHandlerConnect(typed.Uint8Buffer messageArrived) {
        final MqttConnectAckMessage ack = MqttConnectAckMessage()
            .withReturnCode(MqttConnectReturnCode.connectionAccepted);
        broker.sendMessage(ack);
      }

      broker.setMessageHandler = messageHandlerConnect;
    });

    tearDown(() {
      broker?.close();
    });

    test('Connection Keep Alive - Successful response', () async {
      int expectRequest = 0;

      void messageHandlerPingRequest(typed.Uint8Buffer messageArrived) {
        final MqttByteBuffer headerStream = MqttByteBuffer(messageArrived);
        final MqttHeader header = MqttHeader.fromByteBuffer(headerStream);
        if (expectRequest <= 3) {
          print(
              'Connection Keep Alive - Successful response - Ping Request received $expectRequest');
          expect(header.messageType, MqttMessageType.pingRequest);
          expectRequest++;
        }
      }

      await broker.start();
      final events.EventBus clientEventBus = events.EventBus();
      final SynchronousMqttConnectionHandler ch =
          SynchronousMqttConnectionHandler(clientEventBus);
      ch.secure = true;
      final SecurityContext context = SecurityContext.defaultContext;
      final String currDir = path.current + path.separator;
      context.setTrustedCertificates(
          currDir + path.join('test', 'pem', 'localhost.cert'));
      ch.securityContext = context;
      await ch.connect(mockBrokerAddress, mockBrokerPort,
          MqttConnectMessage().withClientIdentifier(testClientId));
      expect(ch.connectionStatus.state, MqttConnectionState.connected);
      broker.setMessageHandler = messageHandlerPingRequest;
      final MqttConnectionKeepAlive ka = MqttConnectionKeepAlive(ch, 2);
      print(
          'Connection Keep Alive - Successful response - keepealive ms is ${ka.keepAlivePeriod}');
      print(
          'Connection Keep Alive - Successful response - ping timer active is ${ka.pingTimer.isActive.toString()}');
      final Stopwatch stopwatch = Stopwatch()..start();
      await MqttUtilities.asyncSleep(10);
      print('Connection Keep Alive - Successful response - Elapsed time '
          'is ${stopwatch.elapsedMilliseconds / 1000} seconds');
      ka.stop();
      ch.close();
    });

    test(
        'Self-signed certificate - Failed with error - Handshake error in client',
        () async {
      bool cbCalled = false;
      void disconnectCB() {
        cbCalled = true;
      }

      broker.pemName = 'self_signed';
      await broker.start();
      final events.EventBus clientEventBus = events.EventBus();
      final SynchronousMqttConnectionHandler ch =
          SynchronousMqttConnectionHandler(clientEventBus);
      ch.secure = true;
      ch.onDisconnected = disconnectCB;
      final SecurityContext context = SecurityContext();
      final String currDir = path.current + path.separator;
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
      final events.EventBus clientEventBus = events.EventBus();
      final SynchronousMqttConnectionHandler ch =
          SynchronousMqttConnectionHandler(clientEventBus);
      ch.secure = true;
      // Skip bad certificate
      ch.onBadCertificate = (_) => true;
      final SecurityContext context = SecurityContext();
      final String currDir = path.current + path.separator;
      context.setTrustedCertificates(
          currDir + path.join('test', 'pem', 'self_signed.cert'));
      ch.securityContext = context;
      await ch.connect(mockBrokerAddress, mockBrokerPort,
          MqttConnectMessage().withClientIdentifier(testClientId));
      expect(ch.connectionStatus.state, MqttConnectionState.connected);
      ch.close();
    });
  });
}
