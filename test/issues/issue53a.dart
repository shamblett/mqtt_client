import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:mqtt_client/mqtt_client.dart';

Future<int> main() async {
  const String clientId = '5bc71e3ea74ad804cc04a856';
  const String token = '2844865:94da2a801302660754642a85592f7755';
  const String id = '2844865';

  final MqttClient client = MqttClient('wss://m4.gap.im/mqtt', clientId);
  client.setProtocolV311();
  client.keepAlivePeriod = 60;
  client.port = 443;
  client.useWebSocket = true;
  client.logging(on: true);

  client.onDisconnected = () {
    print('\n\n\n==> Disconnected | Time: ${DateTime.now().toUtc()}\n\n\n');
    client.disconnect();
  };

  client.connectionMessage = MqttConnectMessage()
      .authenticateAs(id, token)
      .withClientIdentifier(clientId);

  client.connectionMessage.startClean();

  await client.connect().then((MqttClientConnectionStatus e) async {
    client.subscribe('u/$id', MqttQos.exactlyOnce);

    await MqttUtilities.asyncSleep(2);

    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(
      json.encode(
        <String, dynamic>{
          'type': 'msgText',
          'data': 'TextMessage',
          'identifier': Random().nextInt(1000000),
        },
      ),
    );

    client.publishMessage('u/$id', MqttQos.exactlyOnce, builder.payload);
  }).catchError(() {
    print('Connection failed');
  });

  print('Client exiting');

  return 0;
}
