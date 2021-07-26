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

class MockKA extends Mock implements MqttConnectionKeepAlive {
  MockKA(IMqttConnectionHandler connectionHandler, int keepAliveSeconds) {
    ka = MqttConnectionKeepAlive(connectionHandler, keepAliveSeconds);
  }

  late MqttConnectionKeepAlive ka;
}

void main() {
  group('Normal operation', () {
    test('Successful response', () async {
      final clientEventBus = events.EventBus();
      final ch = MockCH(
        clientEventBus,
        maxConnectionAttempts: 3,
      );
      final ka = MqttConnectionKeepAlive(ch, 2);
    });
  });
}
