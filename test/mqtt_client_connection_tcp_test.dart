/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/06/2017
 * Copyright :  S.Hamblett
 */
import 'dart:io';
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
    ka = MqttConnectionKeepAlive(connectionHandler, keepAliveSeconds);
  }
}

/// Don't run some tests on Travis, easier to do this than find out why they
/// run locally on both windows and linux but not on Travis
bool skipIfTravis() {
  bool ret = false;
  final Map<String, String> envVars = Platform.environment;
  if (envVars['TRAVIS'] == 'true') {
    // Skip
    ret = true;
  }
  return ret;
}

void main() {
  // Test wide variables
  final MockBroker broker = MockBroker();
  final String mockBrokerAddress = "localhost";
  final int mockBrokerPort = 1883;
  final String testClientId = "syncMqttTests";
  final String nonExistantHostName = "aabbccddeeffeeddccbbaa.aa.bb";
  final int badPort = 1884;

  group("Connection Keep Alive - Mock tests", () {
    // Group setup
    final MockCH ch = MockCH();
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
    test("Connect to bad host name", () {
      final SynchronousMqttConnectionHandler ch =
      SynchronousMqttConnectionHandler();
      final t1 = expectAsync0(() {
        ch.connect(nonExistantHostName, mockBrokerPort,
            MqttConnectMessage().withClientIdentifier(testClientId));
        expect(ch.connectionState, ConnectionState.connecting);
      });
      t1();
    });
    test("Connect invalid port", () {
      final SynchronousMqttConnectionHandler ch =
      SynchronousMqttConnectionHandler();
      final t1 = expectAsync0(() {
        ch.connect(mockBrokerAddress, badPort,
            MqttConnectMessage().withClientIdentifier(testClientId));
        expect(ch.connectionState, ConnectionState.connecting);
      });
      t1();
    });
    test("Connect no connect ack", () {
      final SynchronousMqttConnectionHandler ch =
      SynchronousMqttConnectionHandler();
      final t1 = expectAsync0(() {
        ch.connect(mockBrokerAddress, mockBrokerPort,
            MqttConnectMessage().withClientIdentifier(testClientId));
      });
      t1();
    });
    test("Successful response and disconnect", () async {
      void messageHandler(typed.Uint8Buffer messageArrived) {
        final MqttConnectAckMessage ack = MqttConnectAckMessage()
            .withReturnCode(MqttConnectReturnCode.connectionAccepted);
        broker.sendMessage(ack);
      }

      final SynchronousMqttConnectionHandler ch =
      SynchronousMqttConnectionHandler();
      broker.setMessageHandler(messageHandler);
      await broker.start();
      await ch.connect(mockBrokerAddress, mockBrokerPort,
          MqttConnectMessage().withClientIdentifier(testClientId));
      expect(ch.connectionState, ConnectionState.connected);
      final ConnectionState state = ch.disconnect();
      expect(state, ConnectionState.disconnected);
      broker.close();
    });
  }, skip: skipIfTravis());

  group("Connection Keep Alive - Mock broker", () {
    test("Successful response", () async {
      int expectRequest = 0;

      void messageHandlerConnect(typed.Uint8Buffer messageArrived) {
        final MqttByteBuffer headerStream = MqttByteBuffer(messageArrived);
        final MqttHeader header = MqttHeader.fromByteBuffer(headerStream);
        expect(header.messageType, MqttMessageType.connect);
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

      final SynchronousMqttConnectionHandler ch =
      SynchronousMqttConnectionHandler();
      broker.setMessageHandler(messageHandlerConnect);
      await ch.connect(mockBrokerAddress, mockBrokerPort,
          MqttConnectMessage().withClientIdentifier(testClientId));
      expect(ch.connectionState, ConnectionState.connected);
      final MqttConnectionKeepAlive ka = MqttConnectionKeepAlive(ch, 2);
      broker.setMessageHandler(messageHandlerPingRequest);
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
    });
  }, skip: skipIfTravis());

  group("Client interface Mock broker", () {
    test("Normal publish", () async {
      void messageHandlerConnect(typed.Uint8Buffer messageArrived) {
        final MqttConnectAckMessage ack = MqttConnectAckMessage()
            .withReturnCode(MqttConnectReturnCode.connectionAccepted);
        broker.sendMessage(ack);
      }

      broker.setMessageHandler(messageHandlerConnect);
      final MqttClient client = MqttClient("localhost", "SJHMQTTClient");
      client.logging(true);
      final String username = "unused";
      print(username);
      final password = "password";
      print(password);
      await client.connect();
      if (client.connectionState == ConnectionState.connected) {
        print("Client connected");
      } else {
        print(
            "ERROR Client connection failed - disconnecting, state is ${client
                .connectionState}");
        client.disconnect();
      }
      // Publish a known topic
      final String topic = "Dart/SJH/mqtt_client";
      final typed.Uint8Buffer buff = typed.Uint8Buffer(5);
      buff[0] = 'h'.codeUnitAt(0);
      buff[1] = 'e'.codeUnitAt(0);
      buff[2] = 'l'.codeUnitAt(0);
      buff[3] = 'l'.codeUnitAt(0);
      buff[4] = 'o'.codeUnitAt(0);
      client.publishMessage(topic, MqttQos.exactlyOnce, buff);
      print("Sleeping....");
      await MqttUtilities.asyncSleep(10);
      print("Disconnecting");
      client.disconnect();
    });
  }, skip: skipIfTravis());
}
