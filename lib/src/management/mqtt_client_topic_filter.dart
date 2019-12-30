/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 01/02/2019
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

// ignore_for_file: unnecessary_final
// ignore_for_file: omit_local_variable_types
// ignore_for_file: avoid_print
// ignore_for_file: avoid_annotating_with_dynamic
// ignore_for_file: avoid_types_on_closure_parameters

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
    _clientUpdates.listen(_topicIn);
    _updates =
        StreamController<List<MqttReceivedMessage<MqttMessage>>>.broadcast(
            sync: true);
  }

  final String _topic;

  SubscriptionTopic _subscriptionTopic;

  /// The topic on which to filter
  String get topic => _topic;

  final Stream<List<MqttReceivedMessage<MqttMessage>>> _clientUpdates;

  StreamController<List<MqttReceivedMessage<MqttMessage>>> _updates;

  /// The stream on which all matching topic updates are published to
  Stream<List<MqttReceivedMessage<MqttMessage>>> get updates => _updates.stream;

  void _topicIn(List<MqttReceivedMessage<MqttMessage>> c) {
    String lastTopic;
    try {
      // Pass through if we have a match
      final List<MqttReceivedMessage<MqttMessage>> tmp =
          <MqttReceivedMessage<MqttMessage>>[];
      for (final MqttReceivedMessage<MqttMessage> message in c) {
        lastTopic = message.topic;
        if (_subscriptionTopic.matches(PublicationTopic(message.topic))) {
          tmp.add(message);
        }
      }
      if (tmp.isNotEmpty) {
        _updates.add(tmp);
      }
      // ignore: avoid_catching_errors
    } on RangeError catch (e) {
      MqttLogger.log('MqttClientTopicFilter::_topicIn - cannot process '
          'received topic: $lastTopic');
      MqttLogger.log('MqttClientTopicFilter::_topicIn - exception is $e');
    }
  }
}
