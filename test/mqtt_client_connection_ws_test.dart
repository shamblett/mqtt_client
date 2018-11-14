/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/06/2017
 * Copyright :  S.Hamblett
 */

import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'package:event_bus/event_bus.dart' as events;
import 'support/mqtt_client_mockbroker.dart';


void main() {
  // Test wide variables
  final MockBrokerWs brokerWs = MockBrokerWs();
  const String mockBrokerAddressWs = 'ws://localhost/ws';
  const String mockBrokerAddressWsNoScheme = 'localhost.com';
  const String mockBrokerAddressWsBad = '://localhost.com';
  const int mockBrokerPortWs = 8090;
  const String testClientId = 'syncMqttTests';

  group('Connection parameters', () {
    test('Invalid URL', () async {
      try {
        final events.EventBus clientEventBus = events.EventBus();
        final SynchronousMqttConnectionHandler ch =
        SynchronousMqttConnectionHandler(clientEventBus);
        ch.useWebSocket = true;
        await ch.connect(mockBrokerAddressWsBad, mockBrokerPortWs,
            MqttConnectMessage().withClientIdentifier(testClientId));
      } on Exception catch (e) {
        expect(e is NoConnectionException, true);
        expect(
            e.toString(),
            'mqtt-client::NoConnectionException: '
                'MqttWsConnection::The URI supplied for the WS connection is not valid - ://localhost.com');
      }
    });

    test('Invalid URL - bad scheme', () async {
      try {
        final events.EventBus clientEventBus = events.EventBus();
        final SynchronousMqttConnectionHandler ch =
        SynchronousMqttConnectionHandler(clientEventBus);
        ch.useWebSocket = true;
        await ch.connect(mockBrokerAddressWsNoScheme, mockBrokerPortWs,
            MqttConnectMessage().withClientIdentifier(testClientId));
      } on Exception catch (e) {
        expect(e is NoConnectionException, true);
        expect(
            e.toString(),
            'mqtt-client::NoConnectionException: '
                'MqttWsConnection::The URI supplied for the WS has an incorrect scheme - $mockBrokerAddressWsNoScheme');
      }
    });
  }, skip: false);

  group('Connection Keep Alive - Mock broker WS', () {
    test('Successful response WS', () async {
      int expectRequest = 0;

      void messageHandlerConnect(typed.Uint8Buffer messageArrived) {
        final MqttConnectAckMessage ack = MqttConnectAckMessage()
            .withReturnCode(MqttConnectReturnCode.connectionAccepted);
        brokerWs.sendMessage(ack);
      }

      void messageHandlerPingRequest(typed.Uint8Buffer messageArrived) {
        final MqttByteBuffer headerStream = MqttByteBuffer(messageArrived);
        final MqttHeader header = MqttHeader.fromByteBuffer(headerStream);
        if (expectRequest <= 3) {
          print(
              'WS Connection Keep Alive - Successful response - Ping Request received $expectRequest');
          expect(header.messageType, MqttMessageType.pingRequest);
          expectRequest++;
        }
      }

      await brokerWs.start();
      final events.EventBus clientEventBus = events.EventBus();
      final SynchronousMqttConnectionHandler ch =
      SynchronousMqttConnectionHandler(clientEventBus);
      ch.useWebSocket = true;
      brokerWs.setMessageHandler = messageHandlerConnect;
      await ch.connect(mockBrokerAddressWs, mockBrokerPortWs,
          MqttConnectMessage().withClientIdentifier(testClientId));
      expect(ch.connectionState.state, ConnectionState.connected);
      brokerWs.setMessageHandler = messageHandlerPingRequest;
      final MqttConnectionKeepAlive ka = MqttConnectionKeepAlive(ch, 2);
      print(
          'WS Connection Keep Alive - Successful response - keepealive ms is ${ka
              .keepAlivePeriod}');
      print(
          'WS Connection Keep Alive - Successful response - ping timer active is ${ka
              .pingTimer.isActive.toString()}');
      final Stopwatch stopwatch = Stopwatch()
        ..start();
      await MqttUtilities.asyncSleep(10);
      print('WS Connection Keep Alive - Successful response - Elapsed time '
          'is ${stopwatch.elapsedMilliseconds / 1000} seconds');
      ka.stop();
      ch.close();
    });
  }, skip: false);
}
