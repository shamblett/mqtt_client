/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/06/2017
 * Copyright :  S.Hamblett
 */
import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';

void main() {
  // Test wide variables
  final String mockBrokerAddressWsNoScheme = "localhost.com";
  final String mockBrokerAddressWsBad = "://localhost.com";
  final int mockBrokerPortWs = 8080;
  final String testClientId = "syncMqttTests";

  group("Connection parameters", () {
    test("Invalid URL", () async {
      try {
        final SynchronousMqttConnectionHandler ch =
        new SynchronousMqttConnectionHandler();
        ch.useWebSocket = true;
        await ch.connect(mockBrokerAddressWsBad, mockBrokerPortWs,
            new MqttConnectMessage().withClientIdentifier(testClientId));
      } catch (e) {
        expect(e is NoConnectionException, true);
        expect(
            e.toString(),
            "mqtt-client::NoConnectionException: "
                "MqttWsConnection::The URI supplied for the WS connection is not valid - ://localhost.com");
      }
    });

    test("Invalid URL - bad scheme", () async {
      try {
        final SynchronousMqttConnectionHandler ch =
        new SynchronousMqttConnectionHandler();
        ch.useWebSocket = true;
        await ch.connect(mockBrokerAddressWsNoScheme, mockBrokerPortWs,
            new MqttConnectMessage().withClientIdentifier(testClientId));
      } catch (e) {
        expect(e is NoConnectionException, true);
        expect(
            e.toString(),
            "mqtt-client::NoConnectionException: "
                "MqttWsConnection::The URI supplied for the WS has an incorrect scheme - $mockBrokerAddressWsNoScheme");
      }
    });
  }, skip: false);
}
