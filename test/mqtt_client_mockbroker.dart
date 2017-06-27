import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:typed_data/typed_data.dart' as typed;

/// Mocks a broker, such as the RSMB, so that we can test the MqttConnection class, and some bits of the
/// connection handlers that are difficult to test otherwise.
class MockBroker {
  int brokerPort = 1883;
  ServerSocket listener;

  Socket client = null;
  MqttByteBuffer networkstream;
  typed.Uint8Buffer headerBytes = new typed.Uint8Buffer(1);

  MockBroker() {
    ServerSocket.bind("localhost", brokerPort).then((ServerSocket server) {
      listener = server;
      listener.listen(_connectAccept);
    });
  }

  void _connectAccept(Socket clientSocket) {
    client = clientSocket;
    client.listen(_dataArrivedOnConnection);
  }

  void _dataArrivedOnConnection(List<int> data) {
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
      networkstream = null;
    } else {
      final int remaining = length - networkstream.length;
      print("Mock Broker:: remaining bytes $remaining");
    }
  }
//
//  /// <summary>
//  /// Sets a function that will be passed the next message received by the faked out broker.
//  /// </summary>
//  /// <param name="handler"></param>
//  public void SetMessageHandler(Action<byte[]> handler)
//  {
//  messageHandler = handler;
//  }
//
//  /// <summary>
//  /// Sends the message to the client connected to the broker.
//  /// </summary>
//  /// <param name="msg">The Mqtt Message.</param>
//  public void SendMessage(MqttMessage msg)
//  {
//  msg.WriteTo(networkStream);
//  networkStream.Flush();
//  }
//
//  #region IDisposable Members
//
//  public void Dispose()
//  {
//  listener.Stop();
//  GC.SuppressFinalize(this);
//  }
//
//  #endregion
//
//  internal void SendMessage(MqttConnectAckMessage ack)
//  {
//  throw new NotImplementedException();
//  }
//}

}
