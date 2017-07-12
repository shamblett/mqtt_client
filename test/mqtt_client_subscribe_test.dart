/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 11/07/2017
 * Copyright :  S.Hamblett
 */
//import 'dart:io';
//import 'dart:async';
//import 'package:mqtt_client/mqtt_client.dart';
//import 'package:observable/observable.dart';
//
//main() async {
//  MqttLogger.loggingOn = true;
//  // Connect the client
//  final MqttClient client =
//  new MqttClient("test.mosquitto.org", "SJHMQTTClient");
//  await client.connect();
//  if (client.connectionState == ConnectionState.connected) {
//    print("Mosquitto client connected");
//  } else {
//    print(
//        "ERROR Mosquitto client connection failed - disconnecting, state is ${client
//            .connectionState}");
//    client.disconnect();
//  }
//  // Subscribe to a known topic
//  final String topic = "test/hw";
//  final ChangeNotifier<MqttReceivedMessage> cn =
//  client.listenTo(topic, MqttQos.atLeastOnce);
//  cn.changes.listen((List<MqttReceivedMessage> c) {
//    final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
//    final String pt =
//    MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
//    print("Change notification:: payload is <$pt> for topic <$topic>");
//  });
//  print("Sleeping....");
//  await MqttUtilities.asyncSleep(90);
//  print("Disconnecting");
//  client.disconnect();
//}

/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 11/07/2017
 * Copyright :  S.Hamblett
 */
@TestOn("linux")
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';
import 'package:observable/observable.dart';

/// These tests check the mqtt client against several publicly available MQTT broker services.
/// The tests are restricted to a linux environment for no other reason than my windows development
/// box is firewalled and the tests will fail, if you wish to run these tests on Windows please remove
/// the TestOn annotation.
/// Also, the test brokers are pinged first to see if they are available, if not the associated test
/// is not run, this saves tests being marked as fail when in fact this may not be the case.

/// Helper function to ping a server
bool pingServer(String server) {
  final ProcessResult result = Process.runSync('ping', ['-c3', '$server']);
  // Get the exit code from the new process.
  if (result.exitCode == 0) {
    return false;
  } else {
    print("Server - $server is dead, exit code is ${result
        .exitCode} - skipping");
    return true;
  }
}

void main() {
  final bool skipMosquito = pingServer("test.mosquitto.org");
  test("Mosquitto", () async {
    MqttLogger.loggingOn = true;
    final MqttClient client =
    new MqttClient("test.mosquitto.org", "SJHMQTTClient");
    final ConnectionState state = await client.connect();
    expect(state, ConnectionState.connected);
    print("Mosquitto client connected");
    final String topic = "test/hw";
    final ChangeNotifier<MqttReceivedMessage> cn =
    client.listenTo(topic, MqttQos.atLeastOnce);
    cn.changes.listen((List<MqttReceivedMessage> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String pt =
      MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      print("Change notification:: payload is <$pt> for topic <$topic>");
    });
    print("Sleeping....");
    await MqttUtilities.asyncSleep(90);
    client.disconnect();
    print("Mosquitto client disconnected");
  }, skip: skipMosquito);
}
