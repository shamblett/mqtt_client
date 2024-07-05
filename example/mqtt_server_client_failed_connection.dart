/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// An annotated connection attempt failed usage example for mqtt_server_client.
/// to run this example on a linux host please execute 'netcat -l 1883' at the command line.
///
/// First create a client, the client is constructed with a broker name, client identifier
/// and port if needed. The client identifier (short ClientId) is an identifier of each MQTT
/// client connecting to a MQTT broker. As the word identifier already suggests, it should be unique per broker.
/// The broker uses it for identifying the client and the current state of the client. If you don’t need a state
/// to be hold by the broker, in MQTT 3.1.1 you can set an empty ClientId, which results in a connection without any state.
/// A condition is that clean session connect flag is true, otherwise the connection will be rejected.
/// The client identifier can be a maximum length of 23 characters. If a port is not specified the standard port
/// of 1883 is used.
/// If you want to use websockets rather than TCP see below.

/// Connect to a resolvable host that is not running a broker, hence the connection will fail.
/// Set the maximum connection attempts to 3.
final client = MqttServerClient('localhost', '', maxConnectionAttempts: 3);

Future<int> main() async {
  /// Set logging on if needed, defaults to off
  client.logging(on: false);

  /// Set the correct MQTT protocol for mosquito
  client.setProtocolV311();

  /// The connection timeout period can be set if needed, the default is 5 seconds.
  client.connectTimeoutPeriod = 2000; // milliseconds

  /// Add the failed connection attempt callback.
  /// This callback will be called on every failed connection attempt, in the case of this
  /// example it will be called 3 times at a period of 2 seconds.
  client.onFailedConnectionAttempt = failedConnectionAttemptCallback;

  /// Create a connection message to use or use the default one. The default one sets the
  /// client identifier, any supplied username/password and clean session,
  /// an example of a specific one below.
  final connMess = MqttConnectMessage()
      .withClientIdentifier('Mqtt_MyClientUniqueId')
      .withWillTopic('willtopic') // If you set this you must set a will message
      .withWillMessage('My Will message')
      .startClean() // Non persistent session for testing
      .withWillQos(MqttQos.atLeastOnce);
  print('EXAMPLE::Mosquitto client connecting....');
  client.connectionMessage = connMess;

  /// Connect the client, any errors here are communicated via the failed
  /// connection attempts callback

  try {
    await client.connect();
  } on NoConnectionException catch (e) {
    // Raised by the client when connection fails.
    print('EXAMPLE::client exception - $e');
    client.disconnect();
    return -1;
  } on SocketException catch (e) {
    // Raised by the socket layer
    print('EXAMPLE::socket exception - $e');
    client.disconnect();
    return -1;
  }

  /// Check we are not connected
  if (client.connectionStatus!.state != MqttConnectionState.connected) {
    print('EXAMPLE::Mosquitto client not connected');
  }

  return 0;
}

/// Failed connection attempt callback
void failedConnectionAttemptCallback(int attempt) {
  print('EXAMPLE::onFailedConnectionAttempt, attempt number is $attempt');
}
