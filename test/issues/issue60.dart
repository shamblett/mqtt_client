/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';

/// An annotated simple subscribe/publish usage example for mqtt_client. Please read in with reference
/// to the MQTT specification. The example is runnable, also refer to test/mqtt_client_broker_test...dart
/// files for separate subscribe/publish tests.
///
///  First create a client, the client is constructed with a broker name, client identifier
///   and port if needed. The client identifier (short ClientId) is an identifier of each MQTT
///   client connecting to a MQTT broker. As the word identifier already suggests, it should be unique per broker.
///   The broker uses it for identifying the client and the current state of the client. If you don’t need a state
///   to be hold by the broker, in MQTT 3.1.1 you can set an empty ClientId, which results in a connection without any state.
///   A condition is that clean session connect flag is true, otherwise the connection will be rejected.
///   The client identifier can be a maximum length of 23 characters. If a port is not specified the standard port
///   of 1883 is used.

String getHostname() {
  if (Platform.isLinux) {
    return 'test.mosquitto.org';
  } else {
    return 'localhost';
  }
}
final MqttClient client = MqttClient(getHostname(), '');

Future<int> main() async {
  /// A websocket URL must start with ws:// or wss:// or Dart will throw an exception, consult your websocket MQTT broker
  /// for details.
  /// To use websockets add the following lines -:
  /// client.useWebSocket = true;
  /// client.port = 80;  ( or whatever your WS port is)
  /// Note do not set the secure flag if you are using wss, the secure flags is for TCP sockets only.

  /// Set logging on if needed, defaults to off
  client.logging(on: false);

  /// If you intend to use a keep alive value in your connect message that is not the default(60s)
  /// you must set it here
  client.keepAlivePeriod = 20;

  /// Add the unsolicited disconnection callback
  client.onDisconnected = onDisconnected;

  /// Add a subscribed callback, there is also an unsubscribed callback if you need it.
  /// You can add these before connection or change them dynamically after connection if
  /// you wish.
  client.onSubscribed = onSubscribed;

  /// Create a connection message to use or use the default one. The default one sets the
  /// client identifier, any supplied username/password, the default keepalive interval(60s)
  /// and clean session, an example of a specific one below.
  final MqttConnectMessage connMess = MqttConnectMessage()
      .withClientIdentifier('Mqtt_MyClientUniqueId')
      .keepAliveFor(20) // Must agree with the keep alive set above or not set
      .withWillTopic('willtopic') // If you set this you must set a will message
      .withWillMessage('My Will message')
      .startClean() // Non persistent session for testing
      .withWillQos(MqttQos.atLeastOnce);
  print('EXAMPLE::Mosquitto client connecting....');
  client.connectionMessage = connMess;

  /// Connect the client, any errors here are communicated by raising of the appropriate exception. Note
  /// in some circumstances the broker will just disconnect us, see the spec about this, we however eill
  /// never send malformed messages.
  MqttClientConnectionStatus status = MqttClientConnectionStatus();
  try {
    status = await client.connect();
  } on Exception catch (e) {
    print('EXAMPLE::client exception - $e');
  }

  /// Check we are connected
  if (status.state == MqttConnectionState.connected) {
    print('EXAMPLE::Mosquitto client connected');
  } else {
    /// Use status here rather than state if you also want the broker return code.
    print(
        'EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, $status');
    client.disconnect();
    exit(-1);
  }

  print('EXAMPLE::subcribing to invalid topic');
  client.subscribe('house#', MqttQos.atLeastOnce);

  print('EXAMPLE::Sleeping......');
  await MqttUtilities.asyncSleep(20);
  return 0;
}

/// The subscribed callback
void onSubscribed(String topic) {
  print('EXAMPLE::Subscription confirmed for topic $topic');
}

/// The unsolicited disconnect callback
void onDisconnected() {
  print('EXAMPLE::OnDisconnected client callback - Client disconnection');
  if (client.connectionStatus.state != MqttConnectionState.disconnected) {
    print('EXAMPLE::ERROR - client connection state should be disconnected');
  } else {
    print('EXAMPLE::SUCCESS - client is indicating disconnected');
  }
  exit(-1);
}
