/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/08/2017
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt_browser_client.dart';

/// The MQTT connection class for the browser websocket interface
class MqttBrowserWsConnection extends MqttBrowserConnection<WebSocket> {
  /// Default constructor
  MqttBrowserWsConnection(super.eventBus);

  /// Initializes a new instance of the MqttConnection class.
  MqttBrowserWsConnection.fromConnect(
    String server,
    int port,
    events.EventBus eventBus,
  ) : super(eventBus) {
    connect(server, port);
  }

  /// The websocket subprotocol list
  List<String> protocols = MqttClientConstants.protocolsMultipleDefault;

  /// Connect
  @override
  Future<MqttClientConnectionStatus?> connect(String server, int port) {
    final completer = Completer<MqttClientConnectionStatus?>();
    MqttLogger.log('MqttBrowserWsConnection::connect - entered');
    // Add the port if present
    Uri uri;
    try {
      uri = Uri.parse(server);
    } on Exception {
      final message =
          'MqttBrowserWsConnection::connect - The URI supplied for the WS '
          'connection is not valid - $server';
      throw NoConnectionException(message);
    }
    if (uri.scheme != 'ws' && uri.scheme != 'wss') {
      final message =
          'MqttBrowserWsConnection::connect - The URI supplied for the WS has '
          'an incorrect scheme - $server';
      throw NoConnectionException(message);
    }
    uri = uri.replace(port: port);

    final uriString = uri.toString();
    MqttLogger.log('MqttBrowserWsConnection::connect -  WS URL is $uriString');
    try {
      // Connect and save the socket.
      final client = WebSocket(
        uriString,
        protocols.map((e) => e.toJS).toList().toJS,
      );
      this.client = client;
      client.binaryType = 'arraybuffer';
      messageStream = MqttByteBuffer(typed.Uint8Buffer());

      StreamSubscription<Event>? openEvents;
      StreamSubscription<CloseEvent>? closeEvents;
      StreamSubscription<Event>? errorEvents;
      openEvents = client.onOpen.listen((e) {
        MqttLogger.log('MqttBrowserWsConnection::connect - websocket is open');
        openEvents?.cancel();
        closeEvents?.cancel();
        errorEvents?.cancel();
        _startListening();
        return completer.complete();
      });

      closeEvents = client.onClose.listen((e) {
        MqttLogger.log(
          'MqttBrowserWsConnection::connect - websocket is closed',
        );
        openEvents?.cancel();
        closeEvents?.cancel();
        errorEvents?.cancel();
        return completer.complete(MqttClientConnectionStatus());
      });

      errorEvents = client.onError.listen((e) {
        MqttLogger.log(
          'MqttBrowserWsConnection::connect - websocket has erred',
        );
        openEvents?.cancel();
        closeEvents?.cancel();
        errorEvents?.cancel();
        return completer.complete(MqttClientConnectionStatus());
      });
    } on Exception {
      final message =
          'MqttBrowserWsConnection::connect - The connection to the message broker '
          '{$uriString} could not be made.';
      throw NoConnectionException(message);
    }
    MqttLogger.log('MqttBrowserWsConnection::connect - connection is waiting');
    return completer.future;
  }

  /// Connect Auto
  @override
  Future<MqttClientConnectionStatus?> connectAuto(String server, int port) {
    final completer = Completer<MqttClientConnectionStatus?>();
    MqttLogger.log('MqttBrowserWsConnection::connectAuto - entered');
    // Add the port if present
    Uri uri;
    try {
      uri = Uri.parse(server);
    } on Exception {
      final message =
          'MqttBrowserWsConnection::connectAuto - The URI supplied for the WS '
          'connection is not valid - $server';
      throw NoConnectionException(message);
    }
    if (uri.scheme != 'ws' && uri.scheme != 'wss') {
      final message =
          'MqttBrowserWsConnection::connectAuto - The URI supplied for the WS has '
          'an incorrect scheme - $server';
      throw NoConnectionException(message);
    }

    uri = uri.replace(port: port);
    final uriString = uri.toString();
    MqttLogger.log(
      'MqttBrowserWsConnection::connectAuto -  WS URL is $uriString',
    );
    try {
      // Connect and save the socket.
      final client = WebSocket(
        uriString,
        protocols.map((e) => e.toJS).toList().toJS,
      );
      this.client = client;
      client.binaryType = 'arraybuffer';
      messageStream = MqttByteBuffer(typed.Uint8Buffer());

      StreamSubscription<Event>? openEvents;
      StreamSubscription<CloseEvent>? closeEvents;
      StreamSubscription<Event>? errorEvents;
      openEvents = client.onOpen.listen((event) {
        MqttLogger.log(
          'MqttBrowserWsConnection::connectAuto - websocket is open',
        );
        openEvents?.cancel();
        closeEvents?.cancel();
        errorEvents?.cancel();
        _startListening();
        return completer.complete();
      });

      closeEvents = client.onClose.listen((e) {
        MqttLogger.log(
          'MqttBrowserWsConnection::connectAuto - websocket is closed',
        );
        openEvents?.cancel();
        closeEvents?.cancel();
        errorEvents?.cancel();
        return completer.complete(MqttClientConnectionStatus());
      });

      errorEvents = client.onError.listen((e) {
        MqttLogger.log(
          'MqttBrowserWsConnection::connectAuto - websocket has errored',
        );
        openEvents?.cancel();
        closeEvents?.cancel();
        errorEvents?.cancel();
        return completer.complete(MqttClientConnectionStatus());
      });
    } on Exception {
      final message =
          'MqttBrowserWsConnection::connectAuto - The connection to the message broker '
          '{$uriString} could not be made.';
      throw NoConnectionException(message);
    }
    MqttLogger.log(
      'MqttBrowserWsConnection::connectAuto - connection is waiting',
    );
    return completer.future;
  }

  /// Stops listening and closes the socket immediately.
  @override
  void stopListening() {
    for (final listener in listeners) {
      listener.cancel();
    }

    listeners.clear();
  }

  /// Closes the socket immediately.
  @override
  void closeClient() {
    client?.close();
  }

  /// Closes and dispose the socket immediately.
  @override
  void disposeClient() {
    closeClient();
    client = null;
  }

  /// Implement stream subscription
  @override
  List<StreamSubscription> onListen() {
    final webSocket = client;
    if (webSocket == null) {
      throw StateError('webSocket is null');
    }

    return [
      webSocket.onClose.listen((e) {
        MqttLogger.log(
          'MqttBrowserConnection::_startListening - websocket is closed',
        );
        onDone();
      }),
      webSocket.onMessage.listen((MessageEvent e) {
        onData(e.data);
      }),
      webSocket.onError.listen((e) {
        MqttLogger.log(
          'MqttBrowserConnection::_startListening - websocket has errored',
        );
        onError(e);
      }),
    ];
  }

  /// Sends the message in the stream to the broker.
  @override
  void send(MqttByteBuffer message) {
    final messageBytes = message.read(message.length);
    var buffer = messageBytes.buffer;
    var bData = ByteData.view(buffer);
    client?.send(bData.jsify()!);
  }
}
