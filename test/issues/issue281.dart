import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

Future<void> main() async {
  final client = MqttServerClient('mqtt.hsl.fi', 'SJH-TEST');
  client.keepAlivePeriod = 60;
  client.onConnected = onConnected;
  client.onDisconnected = onDisconnected;
  client.logging(on: false);
  client.setProtocolV311();

  // let's connect to mqtt broker
  try {
    client.autoReconnect = true;
    await client.connect();
    client.subscribe("/hfp/v2/journey/#", MqttQos.atMostOnce);
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message!);
      print(
          'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- ${pt.length} -->');
      print('');
    });
  } on NoConnectionException catch (e) {
    print(e.toString());
  }

  await MqttUtilities.asyncSleep(20);
}

void onDisconnected() {
  print('Disconnected');
}

void onConnected() {
  print('Connected');
}
