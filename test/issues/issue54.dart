import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';

Future<int> main() async {
  final MqttClient client = MqttClient('test.mosquitto.org', '');
  client.logging(on: false);
  client.keepAlivePeriod = 60;
  client.onDisconnected = onDisconnected;
  client.onSubscribed = onSubscribed;

  final MqttConnectMessage connMess = MqttConnectMessage()
      .withClientIdentifier('Mqtt_MyClientUniqueId')
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

  /// Check we are connected
  if (client.connectionStatus.state == MqttConnectionState.connected) {
    print('EXAMPLE::Mosquitto client connected');
  } else {
    /// Use status here rather than state if you also want the broker return code.
    print(
        'EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
    client.disconnect();
  }

  const String topic = 'com/spl/mqtt/test';
  client.subscribe(topic, MqttQos.atLeastOnce);

  client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
    final MqttPublishMessage recMess = c[0].payload;
    final String pt =
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
    print(
        'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
    print('');
  });
  final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
  builder.addString('Hello from spl');
  client.subscribe(topic, MqttQos.atLeastOnce);
  client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload);
  print('EXAMPLE::Sleeping....');
  await MqttUtilities.asyncSleep(20);

  print('EXAMPLE::Unsubscribing');
  client.unsubscribe(topic);
  await MqttUtilities.asyncSleep(20);

  /// subscribe again
  print('EXAMPLE::subscribe again....');
  client.subscribe(topic, MqttQos.atMostOnce);
  final MqttClientPayloadBuilder builderM = MqttClientPayloadBuilder();
  builderM.addString('Hello from spl again');
  client.subscribe(topic, MqttQos.exactlyOnce);
  client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload);
  print('EXAMPLE::Sleeping....');
  await MqttUtilities.asyncSleep(10);
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
}
