/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 02/10/2017
 * Copyright :  S.Hamblett
 * 01/19/2019 : Don Edvalson - Added this alternate websocket class to work around AWS deficiencies.
 */

part of mqtt_client;

class _DetachedSocket extends Stream<Uint8List> implements Socket {
  _DetachedSocket(this._socket, this._subscription);

  final StreamSubscription<Uint8List> _subscription;
  final Socket _socket;

  @override
  StreamSubscription<Uint8List> listen(void onData(Uint8List event),
      {Function onError, void onDone(), bool cancelOnError}) {
    _subscription
      ..onData(onData)
      ..onError(onError)
      ..onDone(onDone);
    return _subscription;
  }

  @override
  Encoding get encoding => _socket.encoding;

  @override
  set encoding(Encoding value) => _socket.encoding = value;

  @override
  void write(Object obj) => _socket.write(obj);

  @override
  void writeln([Object obj = '']) => _socket.writeln(obj);

  @override
  void writeCharCode(int charCode) => _socket.writeCharCode(charCode);

  @override
  void writeAll(Iterable<Object> objects, [String separator = '']) =>
      _socket.writeAll(objects, separator);

  @override
  void add(List<int> bytes) => _socket.add(bytes);

  @override
  void addError(Object error, [StackTrace stackTrace]) =>
      _socket.addError(error, stackTrace);

  @override
  Future<dynamic> addStream(Stream<List<int>> stream) =>
      _socket.addStream(stream);

  @override
  void destroy() => _socket.destroy();

  @override
  Future<dynamic> flush() => _socket.flush();

  @override
  Future<dynamic> close() => _socket.close();

  @override
  Future<dynamic> get done => _socket.done;

  @override
  int get port => _socket.port;

  @override
  InternetAddress get address => _socket.address;

  @override
  InternetAddress get remoteAddress => _socket.remoteAddress;

  @override
  int get remotePort => _socket.remotePort;

  @override
  bool setOption(SocketOption option, bool enabled) =>
      _socket.setOption(option, enabled);

  @override
  Uint8List getRawOption(RawSocketOption option) =>
      _socket.getRawOption(option);

  @override
  void setRawOption(RawSocketOption option) => _socket.setRawOption(option);
}

/// The MQTT secure connection class
class MqttWs2Connection extends MqttConnection {
  /// Default constructor
  MqttWs2Connection(this.context, events.EventBus eventBus) : super(eventBus);

  /// Initializes a new instance of the MqttWs2Connection class.
  MqttWs2Connection.fromConnect(
      String server, int port, events.EventBus eventBus)
      : super(eventBus) {
    connect(server, port);
  }

  /// The default websocket subprotocol list
  static const List<String> protocolsMultipleDefault = <String>[
    'mqtt',
    'mqttv3.1',
    'mqttv3.11'
  ];

  /// The default websocket subprotocol list for brokers who expect this field to be a single entry
  static const List<String> protocolsSingleDefault = <String>['mqtt'];

  /// The websocket subprotocol list
  List<String> protocols = protocolsMultipleDefault;

  /// The security context for secure usage
  SecurityContext context;

  StreamSubscription<dynamic> _subscription;

  /// Connect
  @override
  Future<MqttClientConnectionStatus> connect(String server, int port) {
    final Completer<MqttClientConnectionStatus> completer =
        Completer<MqttClientConnectionStatus>();
    MqttLogger.log('MqttWs2Connection::connect');
    Uri uri;
    try {
      uri = Uri.parse(server);
    } on Exception {
      final String message =
          'MqttWsConnection::The URI supplied for the WS2 connection is not valid - $server';
      throw NoConnectionException(message);
    }
    if (uri.scheme != 'wss') {
      final String message =
          'MqttWsConnection::The URI supplied for the WS2 has an incorrect scheme - $server';
      throw NoConnectionException(message);
    }
    if (port != null) {
      uri = uri.replace(port: port);
    }
    final String uriString = uri.toString();
    MqttLogger.log(
        'MqttWs2Connection:: WS URL is $uriString, protocols are $protocols');

    try {
      SecureSocket.connect(uri.host, uri.port, context: context)
          .then((Socket socket) {
        MqttLogger.log('MqttWs2Connection::connect - securing socket');
        _performWSHandshake(socket, uri).then((bool b) {
          client = WebSocket.fromUpgradedSocket(
              _DetachedSocket(socket, _subscription),
              serverSide: false);
          readWrapper = ReadWrapper();
          messageStream = MqttByteBuffer(typed.Uint8Buffer());
          MqttLogger.log('MqttWs2Connection::connect - start listening');
          _startListening();
          completer.complete();
        }).catchError((dynamic e) {
          _onError(e);
          completer.completeError(e);
        });
      });
    } on SocketException catch (e) {
      final String message =
          'MqttWs2Connection::The connection to the message broker {$server}:{$port} could not be made. Error is ${e.toString()}';
      completer.completeError(e);
      throw NoConnectionException(message);
    } on HandshakeException catch (e) {
      final String message =
          'MqttWs2Connection::Handshake exception to the message broker {$server}:{$port}. Error is ${e.toString()}';
      completer.completeError(e);
      throw NoConnectionException(message);
    } on TlsException catch (e) {
      final String message =
          'MqttWs2Connection::TLS exception raised on secure connection. Error is ${e.toString()}';
      throw NoConnectionException(message);
    }
    return completer.future;
  }

  Future<bool> _performWSHandshake(Socket socket, Uri uri) async {
    _response = '';
    final Completer<bool> c = Completer<bool>();
    const String endL = '\r\n';
    final String path = '${uri.path}?${uri.query}';
    final String host = '${uri.host}:${uri.port.toString()}';
    final int now = DateTime.now().millisecondsSinceEpoch;
    final String key = 'mqtt-$now';
    final String key64 = base64.encode(utf8.encode(key));

    String request = 'GET $path HTTP/1.1 $endL';
    request += 'Host: $host$endL';
    request += 'Upgrade: websocket$endL';
    request += 'Connection: Upgrade$endL';
    request += 'Sec-WebSocket-Key: $key64$endL';
    request += 'Sec-WebSocket-Protocol: $protocols$endL';
    request += 'Sec-WebSocket-Version: 13$endL';
    request += endL;
    socket.write(request);
    _subscription = socket.listen((Uint8List data) {
      String s = String.fromCharCodes(data);
      s = s.replaceAll('\r', '');
      if (!_parseResponse(s, key64)) {
        c.complete(true);
      }
    }, onDone: () {
      _subscription.cancel();
      const String message =
          'MqttWs2Connection::TLS connection unexpectedly closed';
      throw NoConnectionException(message);
    });
    return c.future;
  }
}

String _response;
bool _parseResponse(String resp, String key) {
  _response += resp;
  final int bodyOffset = _response.indexOf('\n\n');
  // if we don't have a double newline yet we need to go back for more.
  if (bodyOffset < 0) {
    return true;
  }
  final List<String> lines = _response.substring(0, bodyOffset).split('\n');
  if (lines.isEmpty) {
    throw NoConnectionException(
        'MqttWs2Connection::server returned invalid response');
  }
  // split apart the status line
  final List<String> status = lines[0].split(' ');
  if (status.length < 3) {
    throw NoConnectionException(
        'MqttWs2Connection::server returned malformed status line');
  }
  // make a map of the headers
  final Map<String, String> headers = Map<String, String>();
  lines.removeAt(0);
  for (String l in lines) {
    final int space = l.indexOf(' ');
    if (space < 0) {
      throw NoConnectionException(
          'MqttWs2Connection::server returned malformed header line');
    }
    headers[l.substring(0, space - 1).toLowerCase()] = l.substring(space + 1);
  }
  String body = '';
  // if we have a Content-Length key we can't stop till we read the body.
  if (headers.containsKey('content-length')) {
    final int bodyLength = int.parse(headers['content-length']);
    if (_response.length < bodyOffset + bodyLength + 2) {
      return true;
    }
    body = _response.substring(bodyOffset, bodyOffset + bodyLength + 2);
  }
  // if we make it to here we have read all we are going to read.
  // now lets see if we like what we found.
  if (status[1] != '101') {
    throw NoConnectionException(
        'MqttWs2Connection::server refused to upgrade, response = ${status[1]} - ${status[2]} - $body');
  }

  if (!headers.containsKey('connection') ||
      headers['connection'].toLowerCase() != 'upgrade') {
    throw NoConnectionException(
        'MqttWs2Connection::server returned improper connection header line');
  }
  if (!headers.containsKey('upgrade') ||
      headers['upgrade'].toLowerCase() != 'websocket') {
    throw NoConnectionException(
        'MqttWs2Connection::server returned improper upgrade header line');
  }
  if (!headers.containsKey('sec-websocket-protocol')) {
    throw NoConnectionException(
        'MqttWs2Connection::server failed to return protocol header');
  }
  if (!headers.containsKey('sec-websocket-accept')) {
    throw NoConnectionException(
        'MqttWs2Connection::server failed to return accept header');
  }
  // We build up the accept in the same way the server should
  // then we check that the response is the same.

  // Do not change: https://tools.ietf.org/html/rfc6455#section-1.3
  const String acceptSalt = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';

  final Digest sha1Bytes = sha1.convert(utf8.encode(key + acceptSalt));
  final String encodedSha1Bytes = base64.encode(sha1Bytes.bytes);
  if (encodedSha1Bytes != headers['sec-websocket-accept']) {
    throw NoConnectionException('MqttWs2Connection::handshake mismatch');
  }
  return false;
}
