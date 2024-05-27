/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart';
import '../support/mqtt_client_mock_socket.dart';

///
/// Send connect ack and too short pub message
///
class MqttMockSocketScenario1 extends MockSocket {
  dynamic onDataFunc;
  dynamic onDoneFunc;

  static bool initial = true;

  static Future<MqttMockSocketScenario1> connect(host, int port,
      {sourceAddress, int sourcePort = 0, Duration? timeout}) {
    final completer = Completer<MqttMockSocketScenario1>();
    final extSocket = MqttMockSocketScenario1();
    extSocket.port = port;
    extSocket.host = host;
    completer.complete(extSocket);
    return completer.future;
  }

  @override
  void add(List<int> data) {
    mockBytes.addAll(data);
    if (initial) {
      initial = false;
      final ack = MqttConnectAckMessage()
          .withReturnCode(MqttConnectReturnCode.connectionAccepted);
      final buff = Uint8Buffer();
      final ms = MqttByteBuffer(buff);
      ack.writeTo(ms);
      ms.seek(0);
      final out = Uint8List.fromList(ms.buffer!.toList());
      onDataFunc(out);
    } else {
      final subAck = MqttSubscribeAckMessage().withMessageIdentifier(1);
      final buff = Uint8Buffer();
      final ms = MqttByteBuffer(buff);
      subAck.writeTo(ms);
      ms.seek(0);
      final msList = ms.buffer!.toList();
      final msLast = msList.last;
      var out = Uint8List.fromList(msList.sublist(0, 3));
      onDataFunc(out);
      out = Uint8List.fromList([msLast]);
      onDataFunc(out);
    }
  }

  @override
  StreamSubscription<Uint8List> listen(void Function(Uint8List event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    onDataFunc = onData;
    onDoneFunc = onDone;
    return outgoing;
  }
}

int main() {
  test('Trigger available bytes is less', () async {
    await IOOverrides.runZoned(() async {
      final client = MqttServerClient('localhost', 'abc123');
      client.logging(on: true);
      client.keepAlivePeriod = 1;
      const username = 'unused 4';
      print(username);
      const password = 'password 4';
      print(password);
      await client.connect();
      expect(client.connectionStatus!.state == MqttConnectionState.connected,
          isTrue);
      client.subscribe('theTopic', MqttQos.atLeastOnce);
    },
        socketConnect: (dynamic host, int port,
                {dynamic sourceAddress,
                int sourcePort = 0,
                Duration? timeout}) =>
            MqttMockSocketScenario1.connect(host, port,
                sourceAddress: sourceAddress,
                sourcePort: sourcePort,
                timeout: timeout));
  });

  return 0;
}
