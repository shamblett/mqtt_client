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
  final MqttClient client = MqttClient('ws://alitest.fflux.tech/mqtt', '');

  /// Version must be V3.1.1
  //client.setProtocolV311();

  /// WS
  client.useWebSocket = true;
  client.port = 80;

  /// Set logging on if needed, defaults to off
  client.logging(on: true);

  /// If you intend to use a keep alive value in your connect message that is not the default(60s)
  /// you must set it here
  client.keepAlivePeriod = 10;

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
      .withClientIdentifier('2222')
      .keepAliveFor(10) // Must agree with the keep alive set above or not set
      .withWillTopic(
          'Will-Topic') // If you set this you must set a will message
      .withWillMessage('My Will message')
      .startClean() // Non persistent session for testing
      .withWillRetain()
      .withWillQos(MqttQos.atMostOnce);
  print('EXAMPLE::client connecting....');
  client.connectionMessage = connMess;

  /// Connect the client, any errors here are communicated by raising of the appropriate exception. Note
  /// in some circumstances the broker will just disconnect us, see the spec about this, we however eill
  /// never send malformed messages.
  MqttClientConnectionStatus status = MqttClientConnectionStatus();
  const String password1 =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJBUFAiLCJ1c2VyX2lkIjoiMTM2IiwiaXNzIjoiU2VydmljZSIsImV4cCI6MTU1MjMyMDA0MSwiaWF0IjoxNTUxNDU2MDQxfQ.4ewl7d2y7koxW2dNoRT_rHS7LAN7neMvhwGFxH-FDHk';
  const String userName1 = '00000088';
  const String password2 =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJBUFAiLCJ1c2VyX2lkIjoiMTMzIiwiaXNzIjoiU2VydmljZSIsImV4cCI6MTU1MjQ1ODA5OCwiaWF0IjoxNTUxNTk0MDk4fQ.XAsj5X_oq-eaFjgi8KwsYi-Q926qNwOamxMgJK2YJWk';
  const String userName2 = '00000085';
  try {
    status = await client.connect(userName2, password2);
  } on Exception catch (e) {
    print('EXAMPLE::client exception - $e');
  }

  /// Check we are connected
  if (status.state == MqttConnectionState.connected) {
    print('EXAMPLE::client connected');
  } else {
    /// Use status here rather than state if you also want the broker return code.
    print('EXAMPLE::ERROR client connection failed - disconnecting, $status');
    client.disconnect();
    exit(-1);
  }

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

  await MqttUtilities.asyncSleep(5);
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
