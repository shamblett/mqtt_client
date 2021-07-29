/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// The message available event raised by the Connection class
class MessageAvailable {
  /// Constructor
  MessageAvailable(this._message);

  /// The message associated with the event
  final MqttMessage? _message;

  /// Message
  MqttMessage? get message => _message;
}

/// The connect acknowledge message available event raised by the Connection class
class ConnectAckMessageAvailable {
  /// Constructor
  ConnectAckMessageAvailable(this._message);

  /// The message associated with the event
  final MqttMessage? _message;

  /// Message
  MqttMessage? get message => _message;
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

/// Auto reconnect event
class AutoReconnect {
  /// Constructor
  AutoReconnect({this.userRequested = false, this.wasConnected = false});

  /// If set auto reconnect has been invoked through the client
  /// [doAutoReconnect] method, i.e. a user request.
  bool userRequested = false;

  /// True if the previous state was connected
  bool wasConnected = false;
}

/// Re subscribe event
class Resubscribe {
  /// Constructor
  Resubscribe({this.fromAutoReconnect = false});

  /// If set re subscribe has been triggered from auto reconnect.
  bool fromAutoReconnect = false;
}

/// Disconnect on keep alive on no ping response event
class DisconnectOnNoPingResponse {
  /// Constructor
  DisconnectOnNoPingResponse();
}
