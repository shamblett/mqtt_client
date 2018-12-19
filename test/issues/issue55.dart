import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';

Future<int> main() async {
  final MqttClient client = MqttClient('localhost', '');
  client.logging(on: false);
  client.keepAlivePeriod = 60;

  /// Add the unsolicited disconnection callback
  client.onDisconnected = onDisconnected;

  client.onSubscribed = onSubscribed;

  final MqttConnectMessage connMess = MqttConnectMessage()
      .withClientIdentifier('Mqtt_spl_id')
      .keepAliveFor(60) // Must agree with the keep alive set above or not set
      .withWillTopic('willtopic') // If you set this you must set a will message
      .withWillMessage('My Will message')
      .startClean() // Non persistent session for testing
      .withWillQos(MqttQos.atLeastOnce);
  print('EXAMPLE::Mosquitto client connecting....');
  client.connectionMessage = connMess;

  try {
    await client.connect();
  } on Exception catch (e) {
    print('EXAMPLE::client exception - $e');
    client.disconnect();
  }

  if (client.connectionStatus.state == MqttConnectionState.connected) {
    print('EXAMPLE::Mosquitto client connected');
  } else {
    print(
        'EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
    client.disconnect();
    exit(-1);
  }

  const String topic = 'com/spl/mqtt/connect'; // Not a wildcard topic
  client.subscribe(topic, MqttQos.atLeastOnce);

  client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
    final MqttPublishMessage recMess = c[0].payload;
    final String pt =
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    print(
        'EXAMPLE::1st Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
    print('');
  });

  print('EXAMPLE::Publishing our topic');

  final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
  builder.addString('Hello from sql connect');

  /// Subscribe to it
  client.subscribe(topic, MqttQos.exactlyOnce);

  /// Publish it
  client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload);
  print('EXAMPLE::Sleeping....');
  await MqttUtilities.asyncSleep(20);
  print('EXAMPLE::Disconnecting');
  client.disconnect();
  await MqttUtilities.asyncSleep(10);

  print('EXAMPLE::Connecting again');
  await client.connect();
  print('EXAMPLE::Publishing our topic again');
  await MqttUtilities.asyncSleep(2);
  client.subscribe(topic, MqttQos.exactlyOnce);
  client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
    final MqttPublishMessage recMess = c[0].payload;
    final String pt =
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    print(
        'EXAMPLE::2nd Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
    print('');
  });
  client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload);
  print('EXAMPLE::Sleeping....');
  await MqttUtilities.asyncSleep(20);
  print('end exc');
  return 0;
}

/// The subscribed callback
void onSubscribed(String topic) {
  print('EXAMPLE::Subscription confirmed for topic $topic');
}

/// The unsolicited disconnect callback
void onDisconnected() {
  print('EXAMPLE::OnDisconnected client callback - Client disconnection');
}
