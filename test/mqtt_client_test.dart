/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 11/07/2017
 * Copyright :  S.Hamblett
 */
@TestOn("linux")
import 'dart:io';
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:test/test.dart';

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
    print("Mosquitto client connected");
    expect(state, ConnectionState.connected);
    client.disconnect();
    print("Mosquitto client disconnected");
  }, skip: skipMosquito);
}
