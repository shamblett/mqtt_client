/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 02/10/2017
 * Copyright :  S.Hamblett
 */

import 'dart:async';

//import 'package:path/path.dart' as path;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:typed_data/typed_data.dart' as typed;

Future<int> main() async {
  // Create and connect the client
  final String url = "mqtt.googleapis.com";
  final int port = 443;
  final String clientId =
      "projects/warm-actor-356/locations/europe-west1/registries/home-sensors/devices/dummy-sensor";
  final String username = "unused";
  final password =
      "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1MDcyMTM0NzMsImlhdCI6MTUwNzIwOTg3MywiYXVkIjoid2FybS1hY3Rvci0zNTYifQ.NGLiu9svhI6BhGeodGfbBQGGRjiX4j-9bxQdWWYa_2LEjCHdbmDTQC6eHoDHf6nTMMADiQa3sKqD9cZ1gtdT-wfAzEqvJX1Hy5w0Ex8jqe_qidS8Iwtj1TVsvnlXr6OPyHuwW9hAcuOFdlNIXYqDyXDSFl--qa7HS1zqXEy9FMbg20Y8xNSMk1MLG22i8STvYrQmNfm-ib47WayUojllgy2ukMee_N67G2bXq91U3gU0YhlDX4_INjwSTaAtJ4p70Vvd21NFsVBaf0FdJAix5Zsdk165XXjLU6FsfOAzcdeiazzlPFTC-HvQ1eXz4BLn0AaMIFoOkwV9SgBuTdLX8IU3T2hKchtsNw4r5YJa8qw3hu-egsH8bHmSX1cVhjbdWHWihjOnJO_0ef8jWQ6K87Pwhjrc_mBaKo1REllvGV7bOgXoFXW2t1vnb4MtiC7ZpYo5bR9FUsbO_CVMNYHIld6YSmOeO6GCP7OF9kkhEeHGgIIFjsLiAQaqoTCm0EGTh8dTZoYnpv3mRrOw61BgTjPAFvP9OK0hDw4EWXwINoT1UTCQTXF1no_7TZn4wgy-Glx1RA_EGqgEuDSe77H5Oc0aQHj3c01mwlbHJxsmguhSWgdOdc1WPbXqYkJJhcQ-PUvCGuJL5Ut5500dBztdsYaVaRpReOstj0W-a2AF1nU";
  final MqttClient client = MqttClient(url, clientId);
  client.port = port;
  client.secure = true;
  // V3.1.1 for iot-core
  client.setProtocolV311();
  //final String currDir = path.current + path.separator;
  //client.trustedCertPath = currDir + path.join("test", "pem", "roots.pem");
  client.logging(true);
  await client.connect(username, password);
  if (client.connectionState == ConnectionState.connected) {
    print("iotcore client connected");
  } else {
    print(
        "ERROR iotcore client connection failed - disconnecting, state is ${client
            .connectionState}");
    client.disconnect();
  }
  // Publish a known topic
  final String topic = "/devices/dummy-sensor/events";
  final typed.Uint8Buffer buff = typed.Uint8Buffer(4);
  buff[0] = 'a'.codeUnitAt(0);
  buff[1] = 'b'.codeUnitAt(0);
  buff[2] = 'c'.codeUnitAt(0);
  buff[3] = 'd'.codeUnitAt(0);
  client.publishMessage(topic, MqttQos.exactlyOnce, buff);
  print("Sleeping....");
  await MqttUtilities.asyncSleep(10);
  print("Disconnecting");
  client.disconnect();
  return 0;
}
