/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 20/03/2023
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:typed_data/typed_data.dart';

///
/// The mock socket class
///
class MockSocket extends Mock implements Socket {
  final mockBytes = <int>[];
  final mockBytesUint = Uint8List(500);

  MockSocket();

  @override
  int port = 0;

  String host = '';

  late StreamSubscription<Uint8List> outgoing =
      Stream<Uint8List>.empty().listen((event) {});

  static Future<MockSocket> connect(host, int port,
      {sourceAddress, int sourcePort = 0, Duration? timeout}) {
    final completer = Completer<MockSocket>();
    final extSocket = MockSocket();
    extSocket.port = port;
    extSocket.host = host;
    completer.complete(extSocket);
    return completer.future;
  }

  @override
  void add(List<int> data) {
    mockBytes.addAll(data);
  }

  @override
  StreamSubscription<Uint8List> listen(void Function(Uint8List event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    final out = Uint8List.fromList(mockBytes);
    onData!(out);
    return outgoing;
  }

  @override
  void destroy();

  @override
  Future close() {
    final completer = Completer<Future>();
    return completer.future;
  }
}

///
/// Mock socket scenario classes
///
class MqttSimpleConnect extends MockSocket {
  dynamic onDataFunc;

  static Future<MqttSimpleConnectWithDisconnect> connect(host, int port,
      {sourceAddress, int sourcePort = 0, Duration? timeout}) {
    final completer = Completer<MqttSimpleConnectWithDisconnect>();
    final extSocket = MqttSimpleConnectWithDisconnect();
    extSocket.port = port;
    extSocket.host = host;
    completer.complete(extSocket);
    return completer.future;
  }

  @override
  void add(List<int> data) {
    mockBytes.addAll(data);
    final ack = MqttConnectAckMessage()
        .withReturnCode(MqttConnectReturnCode.connectionAccepted);
    final buff = Uint8Buffer();
    final ms = MqttByteBuffer(buff);
    ack.writeTo(ms);
    ms.seek(0);
    final out = Uint8List.fromList(ms.buffer!.toList());
    onDataFunc(out);
  }

  @override
  StreamSubscription<Uint8List> listen(void Function(Uint8List event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    onDataFunc = onData;
    return outgoing;
  }
}

class MqttSimpleConnectWithDisconnect extends MockSocket {
  dynamic onDataFunc;
  dynamic onDoneFunc;

  static bool initial = true;

  static Future<MqttSimpleConnectWithDisconnect> connect(host, int port,
      {sourceAddress, int sourcePort = 0, Duration? timeout}) {
    final completer = Completer<MqttSimpleConnectWithDisconnect>();
    final extSocket = MqttSimpleConnectWithDisconnect();
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
      onDoneFunc();
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
