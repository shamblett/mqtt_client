import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';

Future<int> main() async {
  const String correct =
      '[123, 34, 116, 121, 112, 101, 34, 58, 34, 109, 115, 103, 84, 101, 120, 116, 34, 44, 34, 100, 97, 116, 97, 34, 58, 34, 216, 170, 216, 179, 216, 170, 32, 240, 159, 152, 128, 32, 240, 159, 152, 129, 32, 34, 125]';

  final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
  builder.addString(
    json.encode(
      {
        'type': 'msgText',
        'data': 'تست 😀 😁 ',
      },
    ),
  );

  if (builder.payload.toString() != correct) {
    exit(-1);
  }

  return 0;
}
