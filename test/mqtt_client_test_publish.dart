/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 11/07/2017
 * Copyright :  S.Hamblett
 */
import 'package:typed_data/typed_data.dart' as typed;
import 'package:mqtt_client/mqtt_client.dart';

main() async {
  MqttLogger.loggingOn = true;
  // Connect the client
  final MqttClient client =
  new MqttClient("test.mosquitto.org", "SJHMQTTClient");
  await client.connect();
  if (client.connectionState == ConnectionState.connected) {
    print("Mosquitto client connected");
  } else {
    print(
        "ERROR Mosquitto client connection failed - disconnecting, state is ${client
            .connectionState}");
    client.disconnect();
  }
  // Publish a known topic
  final String topic = "Dart/SJH/mqtt_client";
  final typed.Uint8Buffer buff = new typed.Uint8Buffer(5);
  buff[0] = 'h'.codeUnitAt(0);
  buff[1] = 'e'.codeUnitAt(0);
  buff[2] = 'l'.codeUnitAt(0);
  buff[3] = 'l'.codeUnitAt(0);
  buff[4] = '0'.codeUnitAt(0);
  client.publishMessage(topic, MqttQos.atLeastOnce, buff);
  print("Sleeping....");
  await MqttUtilities.asyncSleep(10);
  print("Disconnecting");
  client.disconnect();
}
