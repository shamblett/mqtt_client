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

/// These tests check the mqtt client subscribe/publish functionality against a publicly
/// available(Mosquitto) MQTT broker.
/// The tests are restricted to a linux environment for no other reason than my windows development
/// box is firewalled and the tests will fail, if you wish to run these tests on Windows please remove
/// the TestOn annotation. The servers are pinged first just to ensure they are up before the tests are run.

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
  final bool skipTests = pingServer("test.mosquitto.org");
  test("Broker Subscribe", () {
    final ProcessResult result =
    Process.runSync('dart', ['test/mqtt_client_broker_test_subscribe.dart']);
    print("Broker Subscribe::stdout");
    print(result.stdout.toString());
    print("Broker Subscribe::stderr");
    print(result.stderr.toString());
    expect(result.exitCode, 0);
  }, skip: skipTests);

  test("Broker Publish", () {
    final ProcessResult result =
    Process.runSync('dart', ['test/mqtt_client_broker_test_publish.dart']);
    print("Broker Publish::stdout");
    print(result.stdout.toString());
    print("Broker Publish::stderr");
    print(result.stderr.toString());
    expect(result.exitCode, 0);
  }, skip: skipTests);

}
