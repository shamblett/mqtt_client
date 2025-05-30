/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/06/2017
 * Copyright :  S.Hamblett
 */

part of '../../../mqtt_server_client.dart';

/// The MQTT client server connection base class
abstract class MqttServerConnection<T extends Object>
    extends MqttConnectionBase<T> {
  /// Socket timeout OS error codes.
  static const wsaETimedOut = 10060;
  static const eTimedOut = 110;

  /// Socket options, applicable only to TCP sockets
  List<RawSocketOption> socketOptions = <RawSocketOption>[];

  /// Socket timeout duration
  Duration? socketTimeout;

  /// Default constructor
  MqttServerConnection(
    super.clientEventBus,
    this.socketOptions,
    this.socketTimeout,
  );

  /// Initializes a new instance of the MqttConnection class.
  MqttServerConnection.fromConnect(
    String server,
    int port,
    events.EventBus clientEventBus,
    this.socketOptions,
    this.socketTimeout,
  ) : super(clientEventBus) {
    connect(server, port);
  }

  /// Implement stream subscription
  StreamSubscription onListen();

  /// OnData listener callback
  @protected
  void onData(dynamic /*String|List<int>*/ data) {
    MqttLogger.log('MqttConnection::onData');
    // Protect against 0 bytes but should never happen.
    if (data.length == 0) {
      MqttLogger.log('MqttServerConnection::onData - Error - 0 byte message');
      return;
    }

    messageStream.addAll(data);

    while (messageStream.isMessageAvailable()) {
      var messageIsValid = true;
      MqttMessage? msg;

      try {
        msg = MqttMessage.createFrom(messageStream);
      } on Exception {
        MqttLogger.log(
          'MqttServerConnection::_ondata - message is not yet valid, '
          'waiting for more data ...',
        );
        messageIsValid = false;
      }
      if (!messageIsValid) {
        messageStream.reset();
        return;
      }
      if (messageIsValid) {
        messageStream.shrink();
        MqttLogger.log(
          'MqttServerConnection::_onData - message received ',
          msg,
        );
        if (!clientEventBus!.streamController.isClosed) {
          if (msg!.header!.messageType == MqttMessageType.connectAck) {
            clientEventBus!.fire(ConnectAckMessageAvailable(msg));
          } else {
            clientEventBus!.fire(MessageAvailable(msg));
          }
          MqttLogger.log(
            'MqttServerConnection::_onData - message available event fired',
          );
        } else {
          MqttLogger.log(
            'MqttServerConnection::_onData - WARN - message available event not fired, event bus is closed',
          );
        }
      }
    }
  }

  // Apply any socket options, true indicates options applied
  bool _applySocketOptions(Socket socket, List<RawSocketOption> socketOptions) {
    if (socketOptions.isNotEmpty) {
      MqttLogger.log(
        'MqttServerConnection::__applySocketOptions - Socket options supplied, applying',
      );
      for (final option in socketOptions) {
        socket.setRawOption(option);
      }
    }
    return socketOptions.isNotEmpty;
  }

  // Check for a timeout exception
  bool _isSocketTimeout(Exception e) {
    if (e is SocketException) {
      // There are different timeout codes for Linux and Windows so check for both
      if (e.osError?.errorCode == wsaETimedOut ||
          e.osError?.errorCode == eTimedOut) {
        return true;
      }
    }
    return false;
  }

  // Create the listening stream subscription and subscribe the callbacks
  void _startListening() {
    stopListening();
    MqttLogger.log('MqttServerConnection::_startListening');
    try {
      listeners.add(onListen());
    } on Exception catch (e) {
      print('MqttServerConnection::_startListening - exception raised $e');
    }
  }
}
