/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 08/010/2017
 * Copyright :  S.Hamblett
 *
 */

import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:typed_data/typed_data.dart' as typed;

/// An example of connecting to the google iot-core MQTT bridge server and publishing to a devices topic.
/// Full setup instructions can be found here https://cloud.google.com/iot/docs/how-tos/mqtt-bridge, please read this
/// before setting up and running this example.
Future<int> main() async {
  // Create and connect the client
  const String url =
      'mqtt.googleapis.com'; // The google iot-core MQTT bridge server
  const int port = 443; // You can also use 8883 if you so wish
  // The client id is a path to your device, example given below, note this contravenes the 23 character client id length
  // from the MQTT specification, the mqtt_client allows this, if exceeded and logging is turned on  a warning is given.
  const String clientId =
      'projects/warm-actor-356/locations/europe-west1/registries/home-sensors/devices/dummy-sensor';
  // User name is not used and can be set to anything, it is needed because the password field contains the encoded JWT token for the device
  const String username = 'unused';
  // Password contains the encoded JWT token, example below, the JWT token when generated should be encoded with the private key coresponding
  // to the public key you have set for your device.
  const String password =
      'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1MDcyMTM0NzMsImlhdCI6MTUwNzIwOTg3MywiYXVkIjoid2FybS1hY3Rvci0zNTYifQ.NGLiu9svhI6BhGeodGfbBQGGRjiX4j-9bxQdWWYa_2LEjCHdbmDTQC6eHoDHf6nTMMADiQa3sKqD9cZ1gtdT-wfAzEqvJX1Hy5w0Ex8jqe_qidS8Iwtj1TVsvnlXr6OPyHuwW9hAcuOFdlNIXYqDyXDSFl--qa7HS1zqXEy9FMbg20Y8xNSMk1MLG22i8STvYrQmNfm-ib47WayUojllgy2ukMee_N67G2bXq91U3gU0YhlDX4_INjwSTaAtJ4p70Vvd21NFsVBaf0FdJAix5Zsdk165XXjLU6FsfOAzcdeiazzlPFTC-HvQ1eXz4BLn0AaMIFoOkwV9SgBuTdLX8IU3T2hKchtsNw4r5YJa8qw3hu-egsH8bHmSX1cVhjbdWHWihjOnJO_0ef8jWQ6K87Pwhjrc_mBaKo1REllvGV7bOgXoFXW2t1vnb4MtiC7ZpYo5bR9FUsbO_CVMNYHIld6YSmOeO6GCP7OF9kkhEeHGgIIFjsLiAQaqoTCm0EGTh8dTZoYnpv3mRrOw61BgTjPAFvP9OK0hDw4EWXwINoT1UTCQTXF1no_7TZn4wgy-Glx1RA_EGqgEuDSe77H5Oc0aQHj3c01mwlbHJxsmguhSWgdOdc1WPbXqYkJJhcQ-PUvCGuJL5Ut5500dBztdsYaVaRpReOstj0W-a2AF1nU';
  // Create the client
  final MqttClient client = MqttClient(url, clientId);
  // Set the port
  client.port = port;
  // Set secure
  client.secure = true;
  // Set the trusted cert path and optionally the private key path. If this is incorrect the TLS handshake will abort and a Handshake
  // exception will be raised, no connect ack message will be received and the broker will disconnect. Note you may not have to do this
  // if your root cert is already cached on your platform, in which case you'll get a an already cached error.
  final String currDir = '${path.current}${path.separator}example${path.separator}';
  client.trustedCertPath = currDir + path.join('pem', 'roots.pem');
  // If needed the private key file path and the optional passphrase
  // client.privateKeyFilePath = "....";
  // client.privateKeyFilePassphrase = "....";
  // If needed the certificate chain path
  // client.certificateChainPath = "....";
  // Set the protocol to V3.1.1 for iot-core, if you fail to do this you will receive a connect ack with the response code
  // 0x01 Connection Refused, unacceptable protocol version
  client.setProtocolV311();
  // logging if you wish
  client.logging(on:true);
  // OK, connect, if your encoded JWT token in the password field cannot be decoded by the corresponding public key attached
  // to the device or the JWT token is incorrect a connect ack message will be received with a return code of
  // 0x05 Connection Refused, not authorized. If the password field is not set at all the return code may be
  // 0x04 Connection Refused, bad user name or password
  await client.connect(username, password);
  if (client.connectionState == ConnectionState.connected) {
    print('iotcore client connected');
  } else {
    print(
        'ERROR iotcore client connection failed - disconnecting, state is ${client
            .connectionState}');
    client.disconnect();
  }
  // Troubleshooting tips can be found here https://cloud.google.com/iot/docs/troubleshooting
  // Publish to the topic you have associated with your device
  const String topic = '/devices/dummy-sensor/events';
  // Use a raw buffer here, see MqttClientPayloadBuilder for payload building assistance.
  final typed.Uint8Buffer buff = typed.Uint8Buffer(4);
  buff[0] = 'a'.codeUnitAt(0);
  buff[1] = 'b'.codeUnitAt(0);
  buff[2] = 'c'.codeUnitAt(0);
  buff[3] = 'd'.codeUnitAt(0);
  client.publishMessage(topic, MqttQos.exactlyOnce, buff);
  print('Sleeping....');
  await MqttUtilities.asyncSleep(10);
  print('Disconnecting');
  client.disconnect();
  return 0;
}
