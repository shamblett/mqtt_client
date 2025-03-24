/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of '../mqtt_client.dart';

/// The message available event raised by the Connection class
class MessageAvailable {

  // The message associated with the event
  final MqttMessage? _message;

  /// Message
  MqttMessage? get message => _message;

  /// Constructor
  MessageAvailable(this._message);

}

/// The connect acknowledge message available event raised by the Connection class
class ConnectAckMessageAvailable {

  // The message associated with the event
  final MqttMessage? _message;

  /// Message
  MqttMessage? get message => _message;

  /// Constructor
  ConnectAckMessageAvailable(this._message);
}

/// Message recieved class for publishing
class MessageReceived {

  // The message associated with the event
  final MqttMessage _message;

  // The topic
  final PublicationTopic _topic;

  /// Message
  MqttMessage get message => _message;

  /// Topic
  PublicationTopic get topic => _topic;

  /// Constructor
  MessageReceived(this._topic, this._message);
}

/// Auto reconnect event
class AutoReconnect {

  /// If set auto reconnect has been invoked through the client
  /// [doAutoReconnect] method, i.e. a user request.
  bool userRequested = false;

  /// True if the previous state was connected
  bool wasConnected = false;

  /// Constructor
  AutoReconnect({this.userRequested = false, this.wasConnected = false});
}

/// Re subscribe event
class Resubscribe {

  /// If set re subscribe has been triggered from auto reconnect.
  bool fromAutoReconnect = false;

  /// Constructor
  Resubscribe({this.fromAutoReconnect = false});
}

/// Disconnect on keep alive on no ping response event
class DisconnectOnNoPingResponse {
  /// Constructor
  DisconnectOnNoPingResponse();
}

/// Disconnect on sent message failed event
class DisconnectOnNoMessageSent {
  /// Constructor
  DisconnectOnNoMessageSent();
}
