import 'dart:io';
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'package:route/server.dart' show Router;

typedef void MessageHandlerFunction(typed.Uint8Buffer message);

/// Helper methods for test message serialization and deserialization
class MessageSerializationHelper {
  /// Invokes the serialization of a message to get an array of bytes that represent the message.
  static typed.Uint8Buffer getMessageBytes(MqttMessage msg) {
    final typed.Uint8Buffer buff = new typed.Uint8Buffer();
    final MqttByteBuffer ms = new MqttByteBuffer(buff);
    msg.writeTo(ms);
    ms.seek(0);
    final typed.Uint8Buffer msgBytes = ms.read(ms.length);
    return msgBytes;
  }
}

/// Mocks a broker, such as the RSMB, so that we can test the MqttConnection class, and some bits of the
/// connection handlers that are difficult to test otherwise. standard TCP connection.
class MockBroker {
  int brokerPort = 1883;
  ServerSocket listener;
  MessageHandlerFunction handler;
  Socket client = null;
  MqttByteBuffer networkstream;
  typed.Uint8Buffer headerBytes = new typed.Uint8Buffer(1);

  MockBroker();

  Future start() {
    final Completer completer = new Completer();
    ServerSocket.bind("localhost", brokerPort).then((ServerSocket server) {
      listener = server;
      listener.listen(_connectAccept);
      print("MockBroker::we are bound");
      return completer.complete();
    });
    return completer.future;
  }
  void _connectAccept(Socket clientSocket) {
    print("MockBroker::connectAccept");
    client = clientSocket;
    client.listen(_dataArrivedOnConnection);
  }

  void _dataArrivedOnConnection(List<int> data) {
    print("MockBroker::data arrived ${data.toString()}");
    final typed.Uint8Buffer dataBytesBuff = new typed.Uint8Buffer();
    dataBytesBuff.addAll(data);
    if (networkstream == null) {
      networkstream = new MqttByteBuffer(dataBytesBuff);
    } else {
      networkstream.write(dataBytesBuff);
    }
    networkstream.seek(0);
    // Assume will have all the data for localhost testing purposes
      final MqttMessage msg = MqttMessage.createFrom(networkstream);
      print(msg.toString());
      handler(networkstream.buffer);
      networkstream = null;
  }

  /// Sets a function that will be passed the next message received by the faked out broker.
  void setMessageHandler(MessageHandlerFunction messageHandler) {
    handler = messageHandler;
  }

  /// Sends the message to the client connected to the broker.
  void sendMessage(MqttMessage msg) {
    print("MockBroker::sending message ${msg.toString()}");
    final typed.Uint8Buffer messBuff = MessageSerializationHelper
        .getMessageBytes(msg);
    print("MockBroker::sending message bytes ${messBuff.toString()}");
    client.add(messBuff.toList());
  }

  /// Close the broker socket
  void close() {
    client.flush();
    client.destroy();
  }
}

/// Mocks a broker, such as the RSMB, so that we can test the MqttConnection class, and some bits of the
/// connection handlers that are difficult to test otherwise. websocket connection.
class MockBrokerWs {

  int port = 8080;
  MessageHandlerFunction handler;
  MqttByteBuffer networkstream;
  typed.Uint8Buffer headerBytes = new typed.Uint8Buffer(1);
  WebSocket _webSocket;

  MockBrokerWs();

  Future start() {
    final Completer completer = new Completer();
    HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, port).then((server) {
      print("Mockbroker WS server is running on "
          "'http://${server.address.address}:$port/'");
      final router = new Router(server);
      // The client will connect using a WebSocket. Upgrade requests to '/ws' and
      // forward them to 'handleWebSocket'.
      router.serve('/ws')
          .transform(new WebSocketTransformer())
          .listen(handleWebSocket);
      return completer.complete();
    });
    return completer.future;
  }

  void handleWebSocket(WebSocket webSocket) {
    // Listen for incoming data.
    _webSocket = webSocket;
    webSocket
        .listen((List<int> data) {
      print("MockBrokerWs::data arrived ${data.toString()}");
      final typed.Uint8Buffer dataBytesBuff = new typed.Uint8Buffer();
      dataBytesBuff.addAll(data);
      if (networkstream == null) {
        networkstream = new MqttByteBuffer(dataBytesBuff);
      } else {
        networkstream.write(dataBytesBuff);
      }
      networkstream.seek(0);
      // Assume will have all the data for localhost testing purposes
      final MqttMessage msg = MqttMessage.createFrom(networkstream);
      print(msg.toString());
      handler(networkstream.buffer);
      networkstream = null;
    }, onError: (error) {
      print("MockBrokerWs::Bad WebSocket request");
    });
  }

  /// Sets a function that will be passed the next message received by the faked out broker.
  void setMessageHandler(MessageHandlerFunction messageHandler) {
    handler = messageHandler;
  }

  /// Sends the message to the client connected to the broker.
  void sendMessage(MqttMessage msg) {
    print("MockBrokerWs::sending message ${msg.toString()}");
    final typed.Uint8Buffer messBuff = MessageSerializationHelper
        .getMessageBytes(msg);
    print("MockBrokerWS::sending message bytes ${messBuff.toString()}");
    _webSocket.add(messBuff.toList());
  }

  /// Close the broker socket
  void close() {
    _webSocket.close();
  }
}
