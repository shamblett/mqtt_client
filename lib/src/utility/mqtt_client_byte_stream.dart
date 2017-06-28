/*
 * Package : mqtt_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2017
 * Copyright (c) 2013, the Dart project authors. All rights reserved.
 */

part of mqtt_client;

/// A stream of chunks of bytes representing a single piece of data.
class ByteStream extends StreamView<List<int>> {
  ByteStream(Stream<List<int>> stream)
      : super(stream);

  /// Returns a single-subscription byte stream that will emit the given bytes
  /// in a single chunk.
  factory ByteStream.fromBytes(List<int> bytes) =>
      new ByteStream(new Stream.fromIterable([bytes]));

  /// Collects the data of this stream in a [Uint8List].
  Future<Uint8List> toBytes() {
    final Completer completer = new Completer<Uint8List>();
    final ByteConversionSink sink = new ByteConversionSink.withCallback((
        bytes) =>
        completer.complete(new Uint8List.fromList(bytes)));
    listen(sink.add, onError: completer.completeError, onDone: sink.close,
        cancelOnError: true);
    return completer.future;
  }

  /// Collect the data of this stream in a [String], decoded according to
  /// [encoding], which defaults to `UTF8`.
  Future<String> bytesToString([Encoding encoding = UTF8]) =>
      encoding.decodeStream(this);

  Stream<String> toStringStream([Encoding encoding = UTF8]) =>
      encoding.decoder.bind(this);
}