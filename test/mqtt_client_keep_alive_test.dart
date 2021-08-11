/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/06/2017
 * Copyright :  S.Hamblett
 */

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:event_bus/event_bus.dart' as events;
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

@TestOn('vm')

// Mock classes
class MockCH extends Mock implements MqttServerConnectionHandler {
  MockCH(var clientEventBus, {required int? maxConnectionAttempts});
  @override
  MqttClientConnectionStatus connectionStatus = MqttClientConnectionStatus();
}

void main() {
  group('Normal operation', () {
    test('Successful response - no pong callback', () async {
      final clientEventBus = events.EventBus();
      var disconnect = false;
      void _disconnectOnNoPingResponse(DisconnectOnNoPingResponse event) {
        disconnect = true;
      }

      clientEventBus
          .on<DisconnectOnNoPingResponse>()
          .listen(_disconnectOnNoPingResponse);
      final ch = MockCH(
        clientEventBus,
        maxConnectionAttempts: 3,
      );
      ch.connectionStatus.state = MqttConnectionState.connected;
      final ka = MqttConnectionKeepAlive(ch, clientEventBus, 2);
      verify(ch.registerForMessage(MqttMessageType.pingRequest, any)).called(1);
      verify(ch.registerForMessage(MqttMessageType.pingResponse, any))
          .called(1);
      verify(ch.registerForAllSentMessages(ka.messageSent)).called(1);
      expect(ka.pingTimer?.isActive, isTrue);
      expect(ka.disconnectTimer, isNull);
      await MqttUtilities.asyncSleep(3);
      verify(ch.sendMessage(any)).called(1);
      final pingMessageRx = MqttPingResponseMessage();
      ka.pingResponseReceived(pingMessageRx);
      expect(disconnect, isFalse);
      ka.stop();
      expect(ka.pingTimer?.isActive, isFalse);
      expect(ka.disconnectTimer, isNull);
    });
    test('Successful response - pong callback', () async {
      var pongCalled = false;
      void pongCallback() {
        pongCalled = true;
      }

      final clientEventBus = events.EventBus();
      var disconnect = false;
      void _disconnectOnNoPingResponse(DisconnectOnNoPingResponse event) {
        disconnect = true;
      }

      clientEventBus
          .on<DisconnectOnNoPingResponse>()
          .listen(_disconnectOnNoPingResponse);
      final ch = MockCH(
        clientEventBus,
        maxConnectionAttempts: 3,
      );
      ch.connectionStatus.state = MqttConnectionState.connected;
      final ka = MqttConnectionKeepAlive(ch, clientEventBus, 2);
      ka.pongCallback = pongCallback;
      verify(ch.registerForMessage(MqttMessageType.pingRequest, any)).called(1);
      verify(ch.registerForMessage(MqttMessageType.pingResponse, any))
          .called(1);
      verify(ch.registerForAllSentMessages(ka.messageSent)).called(1);
      expect(ka.pingTimer?.isActive, isTrue);
      expect(ka.disconnectTimer, isNull);
      await MqttUtilities.asyncSleep(3);
      verify(ch.sendMessage(any)).called(1);
      final pingMessageRx = MqttPingResponseMessage();
      ka.pingResponseReceived(pingMessageRx);
      expect(pongCalled, isTrue);
      expect(disconnect, isFalse);
      ka.stop();
      expect(ka.pingTimer?.isActive, isFalse);
      expect(ka.disconnectTimer, isNull);
    });
  });
  group('Disconnect on no response', () {
    test('Successful response', () async {
      final clientEventBus = events.EventBus();
      var disconnect = false;
      void _disconnectOnNoPingResponse(DisconnectOnNoPingResponse event) {
        disconnect = true;
      }

      clientEventBus
          .on<DisconnectOnNoPingResponse>()
          .listen(_disconnectOnNoPingResponse);
      final ch = MockCH(
        clientEventBus,
        maxConnectionAttempts: 3,
      );
      ch.connectionStatus.state = MqttConnectionState.connected;
      final ka = MqttConnectionKeepAlive(ch, clientEventBus, 2, 2);
      verify(ch.registerForMessage(MqttMessageType.pingRequest, any)).called(1);
      verify(ch.registerForMessage(MqttMessageType.pingResponse, any))
          .called(1);
      verify(ch.registerForAllSentMessages(ka.messageSent)).called(1);
      expect(ka.pingTimer?.isActive, isTrue);
      expect(ka.disconnectTimer, isNull);
      await MqttUtilities.asyncSleep(3);
      expect(ka.disconnectTimer?.isActive, isTrue);
      verify(ch.sendMessage(any)).called(1);
      final pingMessageRx = MqttPingResponseMessage();
      ka.pingResponseReceived(pingMessageRx);
      expect(ka.disconnectTimer?.isActive, isFalse);
      expect(disconnect, isFalse);
      ka.stop();
      expect(ka.pingTimer?.isActive, isFalse);
      expect(ka.disconnectTimer?.isActive, isFalse);
    });
    test('No response', () async {
      final clientEventBus = events.EventBus();
      var disconnect = false;
      void disconnectOnNoPingResponse(DisconnectOnNoPingResponse event) {
        disconnect = true;
      }

      clientEventBus
          .on<DisconnectOnNoPingResponse>()
          .listen(disconnectOnNoPingResponse);
      final ch = MockCH(
        clientEventBus,
        maxConnectionAttempts: 3,
      );
      ch.connectionStatus.state = MqttConnectionState.connected;
      final ka = MqttConnectionKeepAlive(ch, clientEventBus, 2, 2);
      verify(ch.registerForMessage(MqttMessageType.pingRequest, any)).called(1);
      verify(ch.registerForMessage(MqttMessageType.pingResponse, any))
          .called(1);
      verify(ch.registerForAllSentMessages(ka.messageSent)).called(1);
      expect(ka.pingTimer?.isActive, isTrue);
      expect(ka.disconnectTimer, isNull);
      await MqttUtilities.asyncSleep(3);
      expect(ka.disconnectTimer?.isActive, isTrue);
      verify(ch.sendMessage(any)).called(1);
      await MqttUtilities.asyncSleep(2);
      expect(disconnect, isTrue);
      ka.stop();
      expect(ka.pingTimer?.isActive, isFalse);
      expect(ka.disconnectTimer?.isActive, isFalse);
    });
  });
  group('Not connected', () {
    test('No ping sent', () async {
      final clientEventBus = events.EventBus();
      var disconnect = false;
      void _disconnectOnNoPingResponse(DisconnectOnNoPingResponse event) {
        disconnect = true;
      }

      clientEventBus
          .on<DisconnectOnNoPingResponse>()
          .listen(_disconnectOnNoPingResponse);
      final ch = MockCH(
        clientEventBus,
        maxConnectionAttempts: 3,
      );
      ch.connectionStatus.state = MqttConnectionState.disconnected;
      final ka = MqttConnectionKeepAlive(ch, clientEventBus, 2);
      verify(ch.registerForMessage(MqttMessageType.pingRequest, any)).called(1);
      verify(ch.registerForMessage(MqttMessageType.pingResponse, any))
          .called(1);
      verify(ch.registerForAllSentMessages(ka.messageSent)).called(1);
      expect(ka.pingTimer?.isActive, isTrue);
      expect(ka.disconnectTimer, isNull);
      await MqttUtilities.asyncSleep(3);
      verifyNever(ch.sendMessage(any));
      expect(disconnect, isFalse);
      expect(ka.disconnectTimer, isNull);
      ka.stop();
      expect(ka.pingTimer?.isActive, isFalse);
      expect(ka.disconnectTimer, isNull);
    });
  });
}
