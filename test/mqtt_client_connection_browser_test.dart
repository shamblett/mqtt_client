/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 24/01/2020
 * Copyright :  S.Hamblett
 */

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:test/test.dart';
import 'package:event_bus/event_bus.dart' as events;

@TestOn('browser')
void main() {
  const mockBrokerAddressWsNoScheme = 'localhost.com';
  const mockBrokerAddressWsBad = '://localhost.com';
  const mockBrokerPortWs = 8090;
  const testClientId = 'syncMqttTests';

  group('Connection parameters', () {
    test('Invalid URL', () async {
      try {
        final clientEventBus = events.EventBus();
        final ch = SynchronousMqttBrowserConnectionHandler(clientEventBus);
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
        final clientEventBus = events.EventBus();
        final ch = SynchronousMqttBrowserConnectionHandler(clientEventBus);
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
  });
}
