/// Made by Tejas Mehta
/// Made on Sunday, May 09, 2021
/// File Name: chunk_splitter.dart

import 'dart:async';

import 'dart:convert';

class ChunkSplitter implements StreamTransformer<List<int>, List<int>> {

  final int chunkSize;

  ChunkSplitter(this.chunkSize);

  @override
  Stream<List<int>> bind(Stream<List<int>> stream) {
    return Stream<List<int>>.eventTransformed(
        stream, (EventSink<List<int>> sink) => ChunkSplitterEventSink(sink, chunkSize));
  }

  @override
  StreamTransformer<RS, RT> cast<RS, RT>() {
    return StreamTransformer.castFrom(this);
  }

}

class _ChunkSplitterSink extends ByteConversionSinkBase {

  final ByteConversionSink _outSink;
  final int chunkSize;
  _ChunkSplitterSink(this._outSink, this.chunkSize);

  List<int> _carry = [];

  @override
  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    end = RangeError.checkValidRange(start, end, chunk.length);
    if (start >= end) {
      // if (isLast) close();
      return;
    }
    if (_carry.isNotEmpty) {
      chunk = _carry + chunk;
      start = 0;
      end = chunk.length;
      _carry = [];
    }
  }

  @override
  void close() {
    if (_carry.isNotEmpty) {
      while (_carry.length > chunkSize) {
        _outSink.add(_carry.sublist(0, chunkSize));
        _carry = _carry.sublist(chunkSize);
      }
      _outSink.add(_carry);
      _carry = [];
    }
    _outSink.close();
  }


  @override
  void add(List<int> chunk) {
    if (_carry.isNotEmpty) {
      chunk = _carry + chunk;
      _carry = [];
    }
    if (chunk.length == chunkSize) {
      _outSink.add(chunk);
    }
    if (chunk.length > chunkSize) {
      _outSink.add(chunk.sublist(0, chunkSize));
      _carry.addAll(chunk.sublist(chunkSize));
    }
    if (chunk.length < chunkSize) {
      _carry.addAll(chunk);
    }
  }
}

class ChunkSplitterEventSink extends _ChunkSplitterSink
    implements EventSink<List<int>> {
  final EventSink<List<int>> _eventSink;

  final int chunkSize;

  ChunkSplitterEventSink(EventSink<List<int>> eventSink, this.chunkSize)
      : _eventSink = eventSink,
        super(ByteConversionSink.from(eventSink), chunkSize);

  void addError(Object o, [StackTrace? stackTrace]) {
    _eventSink.addError(o, stackTrace);
  }
}
