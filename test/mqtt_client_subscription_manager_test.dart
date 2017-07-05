/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/06/2017
 * Copyright :  S.Hamblett
 */
import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'mqtt_client_test_connection_handler.dart';
import 'package:typed_data/typed_data.dart' as typed;

// Mock classes
class MockCH extends Mock implements MqttConnectionHandler {}

class MockCON extends Mock implements MqttConnection {}

final TestConnectionHandlerNoSend testCHNS = new TestConnectionHandlerNoSend();
final TestConnectionHandlerSend testCHS = new TestConnectionHandlerSend();

void main() {
  group("Manager", () {
    test("Subscription request creates pending subscription", () {});
  });
}
