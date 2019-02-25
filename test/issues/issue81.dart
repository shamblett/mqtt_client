/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';

Future<int> main() async {
  final MqttClient client = MqttClient('mqtt.hsl.fi', '');

  client.secure = true;

  /// Set logging on if needed, defaults to off
  client.logging(on: true);

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
  print('EXAMPLE::client connecting....');
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
    print('EXAMPLE::client connected');
  } else {
    /// Use status here rather than state if you also want the broker return code.
    print(
        'EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, $status');
    client.disconnect();
    exit(-1);
  }

  /// Ok, lets try a subscription
  print(
      'EXAMPLE::Subscribing to the /hfp/v1/journey/ongoing/+/+/+/2550/2/# topic');
  const String topic = '/hfp/v1/journey/ongoing/+/+/+/2550/2/#';
  client.subscribe(topic, MqttQos.atMostOnce);

  /// The client has a change notifier object(see the Observable class) which we then listen to to get
  /// notifications of published updates to each subscribed topic.
  client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
    final MqttPublishMessage recMess = c[0].payload;
    final String pt =
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
    print(
        'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
    print('');
  });

  await MqttUtilities.asyncSleep(2);
  print('EXAMPLE::Disconnecting');
  client.disconnect();
  return 0;
}

/// The subscribed callback
void onSubscribed(String topic) {
  print('EXAMPLE::Subscription confirmed for topic $topic');
}

/// The unsolicited disconnect callback
void onDisconnected() {
  print('EXAMPLE::OnDisconnected client callback - Client disconnection');
  exit(-1);
}
