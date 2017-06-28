/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/06/2017
 * Copyright :  S.Hamblett
 */
import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'mqtt_client_mockbroker.dart';

void main() {
  group("Synchronous MqttConnectionHandler", () {
    // Group wide variables
    MockBroker broker;
    final String mockBrokerAddress = "localhost";
    final int mockBrokerPort = 1883;
    final String testClientId = "syncMqttTests";
    final String nonExistantHostName = "aabbccddeeffeeddccbbaa.aa.bb";
    final int badPort = 1884;

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
    test("Successful response", () async {
      void messageHandler(typed.Uint8Buffer messageArrived) {
        final MqttByteBuffer buff = new MqttByteBuffer(messageArrived);
        final MqttConnectMessage connect = MqttMessage.createFrom(buff);
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
    });
  });
}
