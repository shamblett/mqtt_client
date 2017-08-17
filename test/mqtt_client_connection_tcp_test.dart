/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/06/2017
 * Copyright :  S.Hamblett
 */
import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'mqtt_client_mockbroker.dart';

// Mock classes
class MockCH extends Mock implements MqttConnectionHandler {}

class MockKA extends Mock implements MqttConnectionKeepAlive {
  MqttConnectionKeepAlive ka;

  MockKA(IMqttConnectionHandler connectionHandler, int keepAliveSeconds) {
    ka = new MqttConnectionKeepAlive(connectionHandler, keepAliveSeconds);
  }
}

void main() {
  // Test wide variables
  MockBroker broker;
  final String mockBrokerAddress = "localhost";
  final int mockBrokerPort = 1883;
  final String testClientId = "syncMqttTests";
  final String nonExistantHostName = "aabbccddeeffeeddccbbaa.aa.bb";
  final int badPort = 1884;

  group("Connection Keep Alive - Mock tests", () {
    // Group setup
    final MockCH ch = new MockCH();
    final MockKA ka = new MockKA(ch, 3);
    test("Message sent", () {
      final MqttMessage msg = new MqttPingRequestMessage();
      when(ka.messageSent(msg)).thenReturn(ka.ka.messageSent(msg));
      expect(ka.messageSent(msg), isTrue);
      verify(ka.messageSent(msg));
    });
    test("Ping response received", () {
      final MqttMessage msg = new MqttPingResponseMessage();
      when(ka.pingResponseReceived(msg))
          .thenReturn(ka.ka.pingResponseReceived(msg));
      expect(ka.pingResponseReceived(msg), isTrue);
      verify(ka.pingResponseReceived(msg));
    });
    test("Ping request received", () {
      final MqttMessage msg = new MqttPingRequestMessage();
      when(ka.pingRequestReceived(msg))
          .thenReturn(ka.ka.pingRequestReceived(msg));
      expect(ka.pingRequestReceived(msg), isTrue);
      verify(ka.pingRequestReceived(msg));
    });
    test("Ping required", () {
      when(ka.pingRequired).thenReturn(ka.ka.pingRequired());
      expect(ka.pingRequired(), isNull);
      verify(ka.pingRequired());
      expect(ka.ka.pingTimer, isNotNull);
      expect(ka.ka.pingTimer.isActive, isTrue);
      ka.ka.pingTimer.cancel();
    });
  }, skip: false);

  group("Synchronous MqttConnectionHandler", () {
    test("Connect to bad host name", () {
      final SynchronousMqttConnectionHandler ch =
      new SynchronousMqttConnectionHandler();
      final t1 = expectAsync0(() {
        ch.connect(nonExistantHostName, mockBrokerPort,
            new MqttConnectMessage().withClientIdentifier(testClientId));
        expect(ch.connectionState, ConnectionState.disconnected);
      });
      t1();
    });
    test("Connect invalid port", () {
      final SynchronousMqttConnectionHandler ch =
      new SynchronousMqttConnectionHandler();
      final t1 = expectAsync0(() {
        ch.connect(mockBrokerAddress, badPort,
            new MqttConnectMessage().withClientIdentifier(testClientId));
        expect(ch.connectionState, ConnectionState.disconnected);
      });
      t1();
    });
    test("Connect no connect ack", () {
      broker = new MockBroker();
      final SynchronousMqttConnectionHandler ch =
      new SynchronousMqttConnectionHandler();
      final t1 = expectAsync0(() {
        ch.connect(mockBrokerAddress, mockBrokerPort,
            new MqttConnectMessage().withClientIdentifier(testClientId));
      });
      t1();
    });
    test("Successful response and disconnect", () async {
      void messageHandler(typed.Uint8Buffer messageArrived) {
        final MqttConnectAckMessage ack = new MqttConnectAckMessage()
            .withReturnCode(MqttConnectReturnCode.connectionAccepted);
        broker.sendMessage(ack);
      }

      broker = new MockBroker();
      final SynchronousMqttConnectionHandler ch =
      new SynchronousMqttConnectionHandler();
      broker.setMessageHandler(messageHandler);
      await broker.start();
      await ch.connect(mockBrokerAddress, mockBrokerPort,
          new MqttConnectMessage().withClientIdentifier(testClientId));
      expect(ch.connectionState, ConnectionState.connected);
      final ConnectionState state = ch.disconnect();
      expect(state, ConnectionState.disconnected);
    });
  }, skip: false);

  group("Connection Keep Alive - Mock broker", () {
    test("Successful response", () async {
      int expectRequest = 0;

      void messageHandlerConnect(typed.Uint8Buffer messageArrived) {
        final MqttConnectAckMessage ack = new MqttConnectAckMessage()
            .withReturnCode(MqttConnectReturnCode.connectionAccepted);
        broker.sendMessage(ack);
      }

      void messageHandlerPingRequest(typed.Uint8Buffer messageArrived) {
        final MqttByteBuffer headerStream = new MqttByteBuffer(messageArrived);
        final MqttHeader header = new MqttHeader.fromByteBuffer(headerStream);
        if (expectRequest <= 3) {
          print(
              "Connection Keep Alive - Successful response - Ping Request received $expectRequest");
          expect(header.messageType, MqttMessageType.pingRequest);
          expectRequest++;
        } else {
          print(
              "Connection Keep Alive - Successful response - Ping Response received $expectRequest");
          expect(header.messageType, MqttMessageType.pingResponse);
          expectRequest = 0;
        }
      }

      final SynchronousMqttConnectionHandler ch =
      new SynchronousMqttConnectionHandler();
      broker.setMessageHandler(messageHandlerConnect);
      await ch.connect(mockBrokerAddress, mockBrokerPort,
          new MqttConnectMessage().withClientIdentifier(testClientId));
      expect(ch.connectionState, ConnectionState.connected);
      broker.setMessageHandler(messageHandlerPingRequest);
      final MqttConnectionKeepAlive ka = new MqttConnectionKeepAlive(ch, 2);
      print("Connection Keep Alive - Successful response - keepealive ms is ${ka
          .keepAlivePeriod}");
      print(
          "Connection Keep Alive - Successful response - ping timer active is ${ka
              .pingTimer.isActive.toString()}");
      final Stopwatch stopwatch = new Stopwatch()
        ..start();
      await MqttUtilities.asyncSleep(10);
      print("Connection Keep Alive - Successful response - Elapsed time "
          "is ${stopwatch.elapsedMilliseconds / 1000} seconds");
      final MqttPingRequestMessage prMess = new MqttPingRequestMessage();
      broker.sendMessage(prMess);
      await MqttUtilities.asyncSleep(2);
      ka.stop();
      ch.disconnect();
      ch.close();
    });
  }, skip: false);
}
