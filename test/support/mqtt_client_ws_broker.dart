/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/01/2020
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:io';
import 'package:typed_data/typed_data.dart' as typed;
import 'package:mqtt_client/mqtt_client.dart';

typedef MessageHandlerFunction = void Function(typed.Uint8Buffer message);

/// Helper methods for test message serialization and deserialization
class MessageSerializationHelper {
  /// Invokes the serialization of a message to get an array of bytes that represent the message.
  static typed.Uint8Buffer getMessageBytes(MqttMessage msg) {
    final buff = typed.Uint8Buffer();
    final ms = MqttByteBuffer(buff);
    msg.writeTo(ms);
    ms.seek(0);
    final msgBytes = ms.read(ms.length);
    return msgBytes;
  }
}

/// Mocks a websocket broker, such as the RSMB, so that we can test the [MqttBrowserClient] class,
class MockBrokerWs {
  MockBrokerWs();

  int port = 8090;
  MessageHandlerFunction handler;
  MqttByteBuffer networkstream;
  typed.Uint8Buffer headerBytes = typed.Uint8Buffer(1);
  WebSocket _webSocket;

  void _handleMessage(dynamic data) {
    // Listen for incoming data.
    print('MockBrokerWs::data arrived ${data.toString()}');
    final dataBytesBuff = typed.Uint8Buffer();
    dataBytesBuff.addAll(data);
    if (networkstream == null) {
      networkstream = MqttByteBuffer(dataBytesBuff);
    } else {
      networkstream.write(dataBytesBuff);
    }
    networkstream.seek(0);
    // Assume will have all the data for localhost testing purposes
    final msg = MqttMessage.createFrom(networkstream);
    print(msg.toString());
    handler(networkstream.buffer);
    networkstream = null;
  }

  Future<void> start() {
    final completer = Completer<void>();
    HttpServer.bind(InternetAddress.loopbackIPv4, port).then((dynamic server) {
      print(
          'Mockbroker WS server is running on http://${server.address.address}:$port/');
      server.listen((HttpRequest request) {
        if (request.uri.path == '/ws') {
          WebSocketTransformer.upgrade(request).then((WebSocket websocket) {
            _webSocket = websocket;
            websocket.listen(_handleMessage);
          });
        }
      });
      return completer.complete();
    });
    return completer.future;
  }

  /// Sets a function that will be passed the next message received by the faked out broker.
  set setMessageHandler(MessageHandlerFunction messageHandler) =>
      handler = messageHandler;

  /// Sends the message to the client connected to the broker.
  void sendMessage(MqttMessage msg) {
    print('MockBrokerWs::sending message ${msg.toString()}');
    final messBuff = MessageSerializationHelper.getMessageBytes(msg);
    print('MockBrokerWS::sending message bytes ${messBuff.toString()}');
    _webSocket.add(messBuff.toList());
  }

  /// Close the broker socket
  void close() {
    _webSocket.close();
  }
}

Future<void> main(List<String> argv) async {
  final brokerWs = MockBrokerWs();

  void messageHandlerConnect(typed.Uint8Buffer messageArrived) {
    final ack = MqttConnectAckMessage()
        .withReturnCode(MqttConnectReturnCode.connectionAccepted);
    print('WS Broker - sending connect ack');
    brokerWs.sendMessage(ack);
  }

  print('WS Broker - initializing');
  brokerWs.setMessageHandler = messageHandlerConnect;
  await brokerWs.start();
  print('WS Broker - listening');
}
