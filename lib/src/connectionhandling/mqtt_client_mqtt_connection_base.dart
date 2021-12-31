/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 29/03/2020
 * Copyright :  S.Hamblett
 */

part of mqtt_client;

/// The MQTT client connection base class
class MqttConnectionBase {
  /// Default constructor
  MqttConnectionBase(this.clientEventBus);

  /// Initializes a new instance of the MqttConnection class.
  MqttConnectionBase.fromConnect(String server, int port, this.clientEventBus) {
    connect(server, port);
  }

  /// The socket that maintains the connection to the MQTT broker.
  @protected
  dynamic client;

  /// The stream controller as returned when clients listen.
  @protected
  StreamSubscription? listener;

  /// The read wrapper
  @protected
  ReadWrapper? readWrapper;

  ///The read buffer
  @protected
  late MqttByteBuffer messageStream;

  /// Unsolicited disconnection callback
  @protected
  DisconnectCallback? onDisconnected;

  /// The event bus
  @protected
  events.EventBus? clientEventBus;

  /// Connect for auto reconnect , must be overridden in connection classes
  @protected
  Future<void> connectAuto(String server, int port) {
    final completer = Completer<void>();
    return completer.future;
  }

  /// Connect, must be overridden in connection classes
  @protected
  Future<void> connect(String server, int port) {
    final completer = Completer<void>();
    return completer.future;
  }

  /// OnError listener callback
  @protected
  void onError(dynamic error) {
    _disconnect();
    if (onDisconnected != null) {
      MqttLogger.log(
          'MqttConnectionBase::_onError - calling disconnected callback');
      onDisconnected!();
    }
  }

  /// OnDone listener callback
  @protected
  void onDone() {
    _disconnect();
    if (onDisconnected != null) {
      MqttLogger.log(
          'MqttConnectionBase::_onDone - calling disconnected callback');
      onDisconnected!();
    }
  }

  void _disconnect() {
    if (client != null) {
      listener?.cancel();
      client.destroy();
      client.close();
      client = null;
    }
  }

  /// Stops listening and closes the socket immediately, must be overridden in
  /// connection classes
  void stopListening() {}

  /// User requested or auto disconnect disconnection
  @protected
  void disconnect({bool auto = false}) {
    if (auto) {
      _disconnect();
    } else {
      onDone();
    }
  }
}
