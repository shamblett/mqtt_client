import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

const hostName = 'localhost';

Future<int> main() async {
  final client = MqttServerClient.withPort(hostName, 'SJHIssueTx', 1883);
  client.logging(on: false);
  client.setProtocolV311();
  final connMess = MqttConnectMessage();
  client.connectionMessage = connMess;
  const topic = 'counter';

  print('ISSUE:: client connecting....');
  try {
    await client.connect();
  } on Exception catch (e) {
    print('EXAMPLE::client exception - $e');
    client.disconnect();
  }

  /// Check we are connected
  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print('ISSUE:: client connected');
  } else {
    print(
      'ISSUE::ERROR client connection failed - disconnecting, state is ${client.connectionStatus!.state}',
    );
    client.disconnect();
    exit(-1);
  }

  // Send the counter values
  for (var x = 1; x < 100; x++) {
    await MqttUtilities.asyncSleep(1);
    final builder = MqttClientPayloadBuilder();
    builder.addByte(x);
    print('ISSUE:: Publishing counter value ${builder.payload!}');
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  await MqttUtilities.asyncSleep(2);
  print('ISSUE::Disconnecting');
  client.disconnect();
  return 0;
}
