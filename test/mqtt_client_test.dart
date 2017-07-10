/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/06/2017
 * Copyright :  S.Hamblett
 */
import 'package:mqtt_client/mqtt_client.dart';

main() async {
  final MqttClient client =
      new MqttClient("test.mosquitto.org", "SJHMQTTClient");
  final ConnectionState state = await client.connect();
}
