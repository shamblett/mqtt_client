/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 11/07/2017
 * Copyright :  S.Hamblett
 */
@TestOn('linux')
library;

import 'dart:io';
import 'package:test/test.dart';

/// These tests check the mqtt client subscribe/publish functionality against a publicly
/// available(Mosquitto) MQTT broker.
/// The tests are restricted to a linux environment for no other reason than my windows development
/// box is firewalled and the tests will fail, if you wish to run these tests on Windows please remove
/// the TestOn annotation. The servers are pinged first just to ensure they are up before the tests are run.

/// Helper function to ping a server
bool pingServer(String server) {
  // Not on Travis
  var isDeclared = String.fromEnvironment('PUB_ENVIRONMENT').isNotEmpty;
  if (isDeclared) {
    print('PUB_ENVIRONMENT is declared');
    const noPing = String.fromEnvironment('PUB_ENVIRONMENT');
    if (noPing == 'travis') {
      print('Skipping broker tests, running on travis');
      return true;
    } else {
      print('PUB_ENVIRONMENT is $noPing');
    }
  }
  final result = Process.runSync('ping', <String>['-c3', server]);
  //Get the exit code from the new process.
  if (result.exitCode == 0) {
    return false;
  } else {
    print(
        'Server - $server is dead, exit code is ${result.exitCode} - skipping');
    return true;
  }
}

void main() {
  final skipTests = pingServer('test.mosquitto.org');
  test('Broker Subscribe', () {
    final result = Process.runSync(
        'dart', <String>['test/mqtt_client_broker_test_subscribe.dart']);
    print('Broker Subscribe::stdout');
    print(result.stdout.toString());
    print('Broker Subscribe::stderr');
    print(result.stderr.toString());
    expect(result.exitCode, 0);
  }, skip: skipTests);

  test('Broker Publish', () {
    final result = Process.runSync(
        'dart', <String>['test/mqtt_client_broker_test_publish.dart']);
    print('Broker Publish::stdout');
    print(result.stdout.toString());
    print('Broker Publish::stderr');
    print(result.stderr.toString());
    expect(result.exitCode, 0);
  }, skip: skipTests);
}
