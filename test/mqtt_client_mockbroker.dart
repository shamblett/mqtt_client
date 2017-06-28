import 'dart:io';
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:typed_data/typed_data.dart' as typed;

typedef void MessageHandlerFunction(typed.Uint8Buffer message);

/// Mocks a broker, such as the RSMB, so that we can test the MqttConnection class, and some bits of the
/// connection handlers that are difficult to test otherwise.
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
    final int bytesRead = data.length;
    final typed.Uint8Buffer dataBytesBuff = new typed.Uint8Buffer();
    dataBytesBuff.addAll(data);
    final typed.Uint8Buffer lengthBytes =
    MqttHeader.readLengthBytes(networkstream);
    final int length = MqttHeader.calculateLength(lengthBytes);
    if (networkstream == null) {
      networkstream = new MqttByteBuffer(dataBytesBuff);
    } else {
      networkstream.write(dataBytesBuff);
    }
    if (networkstream.length == length) {
      // We have all the data
      final MqttMessage msg = MqttMessage.createFrom(networkstream);
      print(msg.toString());
      handler(networkstream.buffer);
      networkstream = null;
    } else {
      final int remaining = length - networkstream.length;
      print("Mock Broker:: remaining bytes $remaining");
    }
  }

  /// Sets a function that will be passed the next message received by the faked out broker.
  void setMessageHandler(MessageHandlerFunction messageHandler) {
    handler = messageHandler;
  }

  /// Sends the message to the client connected to the broker.
  void sendMessage(MqttMessage msg) {
    print("MockBroker::sending message ${msg.header.messageType.toString()}");
    MqttByteBuffer mess;
    msg.writeTo(mess);
    _dataArrivedOnConnection(mess.buffer.toList());
  }
}
