/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 01/02/2019
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// This class allows specific topics to be listened for. It essentially
/// acts as a bandpass filter for the topics you are interested in if
/// you subscribe to more than one topic or use wildcard topics.
/// Simply construct it, and listen to its message stream rather than
/// that of the client.
class MqttClientTopicFilter {
  /// Construction
  MqttClientTopicFilter(this._topic, this._clientUpdates) {
    _subscriptionTopic = SubscriptionTopic(_topic);
    _clientUpdates.listen(_topicIn);
    _updates =
        StreamController<List<MqttReceivedMessage<MqttMessage>>>.broadcast(
            sync: true);
  }

  String _topic;

  SubscriptionTopic _subscriptionTopic;

  /// The topic on which to filter
  String get topic => _topic;

  Stream<List<MqttReceivedMessage<MqttMessage>>> _clientUpdates;

  StreamController<List<MqttReceivedMessage<MqttMessage>>> _updates;

  /// The stream on which all matching topic updates are published to
  Stream<List<MqttReceivedMessage<MqttMessage>>> get updates => _updates.stream;

  void _topicIn(List<MqttReceivedMessage<MqttMessage>> c) {
    // Pass through if we have a match
    final List<MqttReceivedMessage<MqttMessage>> tmp =
        List<MqttReceivedMessage<MqttMessage>>();
    for (MqttReceivedMessage<MqttMessage> message in c) {
      if (_subscriptionTopic.matches(PublicationTopic(message.topic))) {
        tmp.add(message);
      }
    }
    if (tmp.isNotEmpty) {
      _updates.add(tmp);
    }
  }
}
