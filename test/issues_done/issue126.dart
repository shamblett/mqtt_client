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

Future<int> main() async {
  final client = MqttServerClient('localhost', '1883');

  /// Version must be V3.1.1
  client.setProtocolV311();

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

  /// Set the client id, user and password
  client.clientIdentifier = 'GID_HOME_APP@@@866554049565137';

  /// Connect the client, any errors here are communicated by raising of the appropriate exception. Note
  /// in some circumstances the broker will just disconnect us, see the spec about this, we however eill
  /// never send malformed messages.
  var status = MqttClientConnectionStatus();
  try {
    status = await client.connect(
        'Signature|LTAI4FqgKhnxCTkovhEXoXLp|post-cn-0pp1c8ab60y',
        'bMen4ngonwNS3is39Y89az1SQCg=');
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

  /// Ok, lets try a subscription
  print(
      'EXAMPLE::Subscribing to the /hfp/v1/journey/ongoing/+/+/+/2550/2/# topic');
  const topic = '/hfp/v1/journey/ongoing/+/+/+/2550/2/#';
  client.subscribe(topic, MqttQos.atMostOnce);

  /// The client has a change notifier object(see the Observable class) which we then listen to to get
  /// notifications of published updates to each subscribed topic.
  client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
    final MqttPublishMessage recMess = c[0].payload;
    final pt =
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
