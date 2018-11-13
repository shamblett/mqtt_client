/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 02/10/2017
 * Copyright :  S.Hamblett
 */

import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'support/mqtt_client_mockbroker.dart';
import 'package:path/path.dart' as path;
import 'package:event_bus/event_bus.dart' as events;

// Mock classes
class MockCH extends Mock implements MqttConnectionHandler {}

class MockKA extends Mock implements MqttConnectionKeepAlive {
  MqttConnectionKeepAlive ka;

  MockKA(IMqttConnectionHandler connectionHandler, int keepAliveSeconds) {
    ka = MqttConnectionKeepAlive(connectionHandler, keepAliveSeconds);
  }
}

void main() {
  // Test wide variables
  final String mockBrokerAddress = "localhost";
  final int mockBrokerPort = 8883;
  final String testClientId = "syncMqttTests";
  final String nonExistantHostName = "aabbccddeeffeeddccbbaa.aa.bb";
  final int badPort = 1884;

  group("Connection Keep Alive - Mock tests", () {
    // Group setup
    final MockCH ch = MockCH();
    when(ch.connectionState).thenReturn(MqttClientConnectionStatus());
    when(ch.secure).thenReturn(true);
    final MockKA ka = MockKA(ch, 3);
    test("Message sent", () {
      final MqttMessage msg = MqttPingRequestMessage();
      when(ka.messageSent(msg)).thenReturn(ka.ka.messageSent(msg));
      expect(ka.messageSent(msg), isTrue);
      verify(ka.messageSent(msg));
    });
    test("Ping response received", () {
      final MqttMessage msg = MqttPingResponseMessage();
      when(ka.pingResponseReceived(msg))
          .thenReturn(ka.ka.pingResponseReceived(msg));
      expect(ka.pingResponseReceived(msg), isTrue);
      verify(ka.pingResponseReceived(msg));
    });
    test("Ping request received", () {
      final MqttMessage msg = MqttPingRequestMessage();
      when(ka.pingRequestReceived(msg))
          .thenReturn(ka.ka.pingRequestReceived(msg));
      expect(ka.pingRequestReceived(msg), isTrue);
      verify(ka.pingRequestReceived(msg));
    });
    test("Ping required", () {
      when(ka.pingRequired()).thenReturn(ka.ka.pingRequired());
      expect(ka.pingRequired(), false);
      verify(ka.pingRequired());
      expect(ka.ka.pingTimer, isNotNull);
      expect(ka.ka.pingTimer.isActive, isTrue);
      ka.ka.pingTimer.cancel();
    });
  }, skip: false);

  group("Synchronous MqttConnectionHandler", () {
    test("Connect to bad host name", () async {
      final events.EventBus clientEventBus = new events.EventBus();
      final SynchronousMqttConnectionHandler ch =
      SynchronousMqttConnectionHandler(clientEventBus);
      ch.secure = true;
      try {
        await ch.connect(nonExistantHostName, mockBrokerPort,
            MqttConnectMessage().withClientIdentifier(testClientId));
      } catch (e) {
        expect(e.toString().contains("Failed host lookup"), isTrue);
        expect(e.toString().contains(nonExistantHostName), isTrue);
      }
      expect(ch.connectionState.state, ConnectionState.faulted);
    }, skip: true);
    test("Connect invalid port", () async {
      final events.EventBus clientEventBus = new events.EventBus();
      final SynchronousMqttConnectionHandler ch =
      SynchronousMqttConnectionHandler(clientEventBus);
      ch.secure = true;
      try {
        await ch.connect(mockBrokerAddress, badPort,
            MqttConnectMessage().withClientIdentifier(testClientId));
      } catch (e) {
        expect(e.toString().contains("refused"), isTrue);
      }
      expect(ch.connectionState.state, ConnectionState.faulted);
    });
  });
  group("Connection Keep Alive - Mock broker", () {
    test("Successful response", () async {
      final MockBrokerSecure broker = MockBrokerSecure();
      int expectRequest = 0;

      void messageHandlerConnect(typed.Uint8Buffer messageArrived) {
        final MqttConnectAckMessage ack = MqttConnectAckMessage()
            .withReturnCode(MqttConnectReturnCode.connectionAccepted);
        broker.sendMessage(ack);
      }

      void messageHandlerPingRequest(typed.Uint8Buffer messageArrived) {
        final MqttByteBuffer headerStream = MqttByteBuffer(messageArrived);
        final MqttHeader header = MqttHeader.fromByteBuffer(headerStream);
        if (expectRequest <= 3) {
          print(
              "Connection Keep Alive - Successful response - Ping Request received $expectRequest");
          expect(header.messageType, MqttMessageType.pingRequest);
          expectRequest++;
        }
      }

      broker.start();
      final events.EventBus clientEventBus = new events.EventBus();
      final SynchronousMqttConnectionHandler ch =
      SynchronousMqttConnectionHandler(clientEventBus);
      ch.secure = true;
      final String currDir = path.current + path.separator;
      ch.trustedCertPath = currDir + path.join("test", "pem", "localhost.cert");
      broker.setMessageHandler(messageHandlerConnect);
      await ch.connect(mockBrokerAddress, mockBrokerPort,
          MqttConnectMessage().withClientIdentifier(testClientId));
      expect(ch.connectionState.state, ConnectionState.connected);
      broker.setMessageHandler(messageHandlerPingRequest);
      final MqttConnectionKeepAlive ka = MqttConnectionKeepAlive(ch, 2);
      print(
          "Connection Keep Alive - Successful response - keepealive ms is ${ka
              .keepAlivePeriod}");
      print(
          "Connection Keep Alive - Successful response - ping timer active is ${ka
              .pingTimer.isActive.toString()}");
      final Stopwatch stopwatch = Stopwatch()
        ..start();
      await MqttUtilities.asyncSleep(10);
      print("Connection Keep Alive - Successful response - Elapsed time "
          "is ${stopwatch.elapsedMilliseconds / 1000} seconds");
      ka.stop();
      ch.close();
    });
  }, skip: false);
}
