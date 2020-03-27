/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/06/2017
 * Copyright :  S.Hamblett
 */

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'package:event_bus/event_bus.dart' as events;
import 'support/mqtt_client_mockbroker.dart';

@TestOn('vm')

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
  final broker = MockBroker();
  const mockBrokerAddress = 'localhost';
  const mockBrokerPort = 1883;
  const testClientId = 'syncMqttTests';
  const nonExistantHostName = 'aabbccddeeffeeddccbbaa.aa.bb';
  const badPort = 1884;

  group('Connection Keep Alive - Mock tests', () {
    // Group setup
    final ch = MockCH();
    when(ch.secure).thenReturn(false);
    final ka = MockKA(ch, 3);
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
  });

  group('Synchronous MqttConnectionHandler', () {
    test('Connect to bad host name', () async {
      final clientEventBus = events.EventBus();
      final ch = SynchronousMqttConnectionHandler(clientEventBus);
      try {
        await ch.connect(nonExistantHostName, mockBrokerPort,
            MqttConnectMessage().withClientIdentifier(testClientId));
      } on Exception catch (e) {
        expect(e.toString().contains('Failed host lookup'), isTrue);
        expect(e.toString().contains(nonExistantHostName), isTrue);
      }
      expect(ch.connectionStatus.state, MqttConnectionState.faulted);
      expect(
          ch.connectionStatus.returnCode, MqttConnectReturnCode.noneSpecified);
    });
    test('Connect invalid port', () async {
      var cbCalled = false;
      void disconnectCB() {
        cbCalled = true;
      }

      final clientEventBus = events.EventBus();
      final ch = SynchronousMqttConnectionHandler(clientEventBus);
      ch.onDisconnected = disconnectCB;
      try {
        await ch.connect(mockBrokerAddress, badPort,
            MqttConnectMessage().withClientIdentifier(testClientId));
      } on Exception catch (e) {
        expect(e.toString().contains('refused'), isTrue);
      }
      expect(ch.connectionStatus.state, MqttConnectionState.faulted);
      expect(
          ch.connectionStatus.returnCode, MqttConnectReturnCode.noneSpecified);
      expect(cbCalled, isTrue);
    });
    test('Connect no connect ack', () async {
      await broker.start();
      final clientEventBus = events.EventBus();
      final ch = SynchronousMqttConnectionHandler(clientEventBus);
      try {
        await ch.connect(mockBrokerAddress, mockBrokerPort,
            MqttConnectMessage().withClientIdentifier(testClientId));
      } on Exception catch (e) {
        expect(e is NoConnectionException, isTrue);
      }
      expect(ch.connectionStatus.state, MqttConnectionState.faulted);
      expect(
          ch.connectionStatus.returnCode, MqttConnectReturnCode.noneSpecified);
    });
    test('Successful response and disconnect', () async {
      var connectCbCalled = false;
      void messageHandler(typed.Uint8Buffer messageArrived) {
        final ack = MqttConnectAckMessage()
            .withReturnCode(MqttConnectReturnCode.connectionAccepted);
        broker.sendMessage(ack);
      }

      void connectCb() {
        connectCbCalled = true;
      }

      final clientEventBus = events.EventBus();
      final ch = SynchronousMqttConnectionHandler(clientEventBus);
      broker.setMessageHandler = messageHandler;
      ch.onConnected = connectCb;
      await ch.connect(mockBrokerAddress, mockBrokerPort,
          MqttConnectMessage().withClientIdentifier(testClientId));
      expect(ch.connectionStatus.state, MqttConnectionState.connected);
      expect(ch.connectionStatus.returnCode,
          MqttConnectReturnCode.connectionAccepted);
      expect(connectCbCalled, isTrue);
      final state = ch.disconnect();
      expect(state, MqttConnectionState.disconnected);
    });
    test('Successful response and disconnect with returned status', () async {
      void messageHandler(typed.Uint8Buffer messageArrived) {
        final ack = MqttConnectAckMessage()
            .withReturnCode(MqttConnectReturnCode.connectionAccepted);
        broker.sendMessage(ack);
      }

      final clientEventBus = events.EventBus();
      final ch = SynchronousMqttConnectionHandler(clientEventBus);
      broker.setMessageHandler = messageHandler;
      final status = await ch.connect(mockBrokerAddress, mockBrokerPort,
          MqttConnectMessage().withClientIdentifier(testClientId));
      expect(status.state, MqttConnectionState.connected);
      expect(status.returnCode, MqttConnectReturnCode.connectionAccepted);
      final state = ch.disconnect();
      expect(state, MqttConnectionState.disconnected);
    });
  });

  group('Connection Keep Alive - Mock broker', () {
    test('Successful response', () async {
      var expectRequest = 0;

      void messageHandlerConnect(typed.Uint8Buffer messageArrived) {
        final headerStream = MqttByteBuffer(messageArrived);
        final header = MqttHeader.fromByteBuffer(headerStream);
        expect(header.messageType, MqttMessageType.connect);
        final ack = MqttConnectAckMessage()
            .withReturnCode(MqttConnectReturnCode.connectionAccepted);
        broker.sendMessage(ack);
      }

      void messageHandlerPingRequest(typed.Uint8Buffer messageArrived) {
        final headerStream = MqttByteBuffer(messageArrived);
        final header = MqttHeader.fromByteBuffer(headerStream);
        if (expectRequest <= 3) {
          print(
              'Connection Keep Alive - Successful response - Ping Request received $expectRequest');
          expect(header.messageType, MqttMessageType.pingRequest);
          expectRequest++;
        }
      }

      final clientEventBus = events.EventBus();
      final ch = SynchronousMqttConnectionHandler(clientEventBus);
      broker.setMessageHandler = messageHandlerConnect;
      await ch.connect(mockBrokerAddress, mockBrokerPort,
          MqttConnectMessage().withClientIdentifier(testClientId));
      expect(ch.connectionStatus.state, MqttConnectionState.connected);
      expect(ch.connectionStatus.returnCode,
          MqttConnectReturnCode.connectionAccepted);
      final ka = MqttConnectionKeepAlive(ch, 2);
      broker.setMessageHandler = messageHandlerPingRequest;
      print(
          'Connection Keep Alive - Successful response - keepealive ms is ${ka.keepAlivePeriod}');
      print(
          'Connection Keep Alive - Successful response - ping timer active is ${ka.pingTimer.isActive.toString()}');
      final stopwatch = Stopwatch()..start();
      await MqttUtilities.asyncSleep(10);
      print('Connection Keep Alive - Successful response - Elapsed time '
          'is ${stopwatch.elapsedMilliseconds / 1000} seconds');
      ka.stop();
    });
  });

  group('Client interface Mock broker', () {
    test('Normal publish', () async {
      void messageHandlerConnect(typed.Uint8Buffer messageArrived) {
        final ack = MqttConnectAckMessage()
            .withReturnCode(MqttConnectReturnCode.connectionAccepted);
        broker.sendMessage(ack);
      }

      broker.setMessageHandler = messageHandlerConnect;
      final client = MqttServerClient('localhost', 'SJHMQTTClient');
      client.logging(on: true);
      const username = 'unused';
      print(username);
      const password = 'password';
      print(password);
      await client.connect();
      if (client.connectionStatus.state == MqttConnectionState.connected) {
        print('Client connected');
      } else {
        print(
            'ERROR Client connection failed - disconnecting, state is ${client.connectionStatus.state}');
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
      print('Sleeping....');
      await MqttUtilities.asyncSleep(10);
      print('Disconnecting');
      client.disconnect();
      expect(client.connectionStatus.state, MqttConnectionState.disconnected);
      broker.close();
    });
  });

}
