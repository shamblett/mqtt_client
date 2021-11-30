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
/// that of the client. Note this class will only filter valid receive topics
/// so if you filter on wildcard topics for instance, which you should only
/// subscribe to,  it  will always generate a no match.
class MqttClientTopicFilter {
  /// Construction
  MqttClientTopicFilter(this._topic, this._clientUpdates) {
    _subscriptionTopic = SubscriptionTopic(_topic);
    _clientUpdates!.listen(_topicIn);
    _updates =
        StreamController<List<MqttReceivedMessage<MqttMessage?>>>.broadcast(
            sync: true);
  }

  final String _topic;

  late SubscriptionTopic _subscriptionTopic;

  /// The topic on which to filter
  String get topic => _topic;

  final Stream<List<MqttReceivedMessage<MqttMessage?>>?>? _clientUpdates;

  late StreamController<List<MqttReceivedMessage<MqttMessage?>>> _updates;

  /// The stream on which all matching topic updates are published to
  Stream<List<MqttReceivedMessage<MqttMessage?>>> get updates =>
      _updates.stream;

  void _topicIn(List<MqttReceivedMessage<MqttMessage?>>? c) {
    String? lastTopic;
    try {
      // Pass through if we have a match
      final List<MqttReceivedMessage<MqttMessage?>> tmp =
          <MqttReceivedMessage<MqttMessage>>[];
      for (final message in c!) {
        lastTopic = message.topic;
        if (_subscriptionTopic.matches(PublicationTopic(message.topic))) {
          tmp.add(message);
        }
      }
      if (tmp.isNotEmpty) {
        _updates.add(tmp);
      }
    } on RangeError catch (e) {
      MqttLogger.log('MqttClientTopicFilter::_topicIn - cannot process '
          'received topic: $lastTopic');
      MqttLogger.log('MqttClientTopicFilter::_topicIn - exception is $e');
    }
  }
}
