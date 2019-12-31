/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

// ignore_for_file: unnecessary_final
// ignore_for_file: omit_local_variable_types

/// The message available event raised by the Connection class
class MessageAvailable {
  /// Constructor
  MessageAvailable(this._message);

  /// The message associated with the event
  final MqttMessage _message;

  /// Message
  MqttMessage get message => _message;
}

/// Message recieved class for publishing
class MessageReceived {
  /// Constructor
  MessageReceived(this._topic, this._message);

  /// The message associated with the event
  final MqttMessage _message;

  /// Message
  MqttMessage get message => _message;

  /// The topic
  final PublicationTopic _topic;

  /// Topic
  PublicationTopic get topic => _topic;
}
