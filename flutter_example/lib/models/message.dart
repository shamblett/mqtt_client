import 'package:mqtt_client/mqtt_client.dart' as mqtt;

class Message {
  final String topic;
  final String message;
  final mqtt.MqttQos qos;

  Message({this.topic, this.message, this.qos});
}
