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
///

///
/// Simple connect, always sends a connect ack once and ignores everything else
/// received.
///
class MqttMockSocketSimpleConnect extends MockSocket {
  dynamic onDataFunc;
  bool initial = true;

  static Future<MqttMockSocketSimpleConnect> connect(host, int port,
      {sourceAddress, int sourcePort = 0, Duration? timeout}) {
    final completer = Completer<MqttMockSocketSimpleConnect>();
    final extSocket = MqttMockSocketSimpleConnect();
    extSocket.port = port;
    extSocket.host = host;
    completer.complete(extSocket);
    return completer.future;
  }

  @override
  void add(List<int> data) {
    mockBytes.addAll(data);
    if (initial) {
      final ack = MqttConnectAckMessage()
          .withReturnCode(MqttConnectReturnCode.connectionAccepted);
      final buff = Uint8Buffer();
      final ms = MqttByteBuffer(buff);
      ack.writeTo(ms);
      ms.seek(0);
      final out = Uint8List.fromList(ms.buffer!.toList());
      initial = false;
      onDataFunc(out);
    }
  }

  @override
  StreamSubscription<Uint8List> listen(void Function(Uint8List event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    onDataFunc = onData;
    return outgoing;
  }
}

///
/// Connect to bad host name
///
class MqttMockSocketInvalidHost extends MockSocket {
  static Future<MqttMockSocketInvalidHost> connect(host, int port,
      {sourceAddress, int sourcePort = 0, Duration? timeout}) {
    final completer = Completer<MqttMockSocketInvalidHost>();
    final extSocket = MqttMockSocketInvalidHost();
    extSocket.port = port;
    extSocket.host = host;
    completer.complete(extSocket);
    return completer.future;
  }

  @override
  void add(List<int> data) {
    mockBytes.addAll(data);
    if (host == 'aabbccddeeffeeddccbbaa.aa.bb') {
      throw SocketException('MockSocket::Failed host lookup $host');
    }
  }

  @override
  StreamSubscription<Uint8List> listen(void Function(Uint8List event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      outgoing;
}

///
/// Connect to bad port
///
class MqttMockSocketInvalidPort extends MockSocket {
  static Future<MqttMockSocketInvalidPort> connect(host, int port,
      {sourceAddress, int sourcePort = 0, Duration? timeout}) {
    final completer = Completer<MqttMockSocketInvalidPort>();
    final extSocket = MqttMockSocketInvalidPort();
    extSocket.port = port;
    extSocket.host = host;
    completer.complete(extSocket);
    return completer.future;
  }

  @override
  void add(List<int> data) {
    mockBytes.addAll(data);
    if (port == 1884) {
      throw SocketException('MockSocket::Connection refused $host');
    }
  }

  @override
  StreamSubscription<Uint8List> listen(void Function(Uint8List event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      outgoing;
}

///
/// Simple connect, never sends a connect ack no matter what is received.
///
class MqttMockSocketSimpleConnectNoAck extends MockSocket {
  dynamic onDataFunc;

  static Future<MqttMockSocketSimpleConnectNoAck> connect(host, int port,
      {sourceAddress, int sourcePort = 0, Duration? timeout}) {
    final completer = Completer<MqttMockSocketSimpleConnectNoAck>();
    final extSocket = MqttMockSocketSimpleConnectNoAck();
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
    onDataFunc = onData;
    return outgoing;
  }
}

///
/// Connected - Broker Disconnects Stays Inactive
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

///
/// Connected - Broker Disconnects Remains Active
///
class MqttMockSocketScenario2 extends MockSocket {
  dynamic onDataFunc;
  dynamic onDoneFunc;

  static bool initial = true;

  static Future<MqttMockSocketScenario2> connect(host, int port,
      {sourceAddress, int sourcePort = 0, Duration? timeout}) {
    final completer = Completer<MqttMockSocketScenario2>();
    final extSocket = MqttMockSocketScenario2();
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
      initial = true;
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

///
/// Connection Keep Alive - Mock broker
///
class MqttMockSocketScenario3 extends MockSocket {
  dynamic onDataFunc;
  dynamic onDoneFunc;

  bool initial = true;

  static Future<MqttMockSocketScenario3> connect(host, int port,
      {sourceAddress, int sourcePort = 0, Duration? timeout}) {
    final completer = Completer<MqttMockSocketScenario3>();
    final extSocket = MqttMockSocketScenario3();
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
      initial = true;
      final pingResp = MqttPingResponseMessage();
      final buff = Uint8Buffer();
      final ms = MqttByteBuffer(buff);
      pingResp.writeTo(ms);
      ms.seek(0);
      final out = Uint8List.fromList(ms.buffer!.toList());
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
