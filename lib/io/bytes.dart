import 'dart:typed_data';

class RSocketByteBuffer {
  List<int> _data = <int>[];
  int _readerIndex = 0;
  int _writerIndex = 0;
  int _capacity = 0;

  static RSocketByteBuffer fromUint8List(Uint8List data) {
    var buffer = RSocketByteBuffer();
    buffer._data = List.from(data);
    buffer._capacity = data.length;
    return buffer;
  }

  static RSocketByteBuffer fromArray(List<int> array) {
    var buffer = RSocketByteBuffer();
    buffer._data = array;
    buffer._capacity = array.length;
    return buffer;
  }

  int? readI8() {
    if (_readerIndex < _capacity) {
      var value = _data[_readerIndex];
      _readerIndex += 1;
      return value;
    }
    return null;
  }

  int? readI16() {
    return bytesToNumber(readBytes(2));
  }

  int? readI24() {
    return bytesToNumber(readBytes(3));
  }

  int? readI32() {
    return bytesToNumber(readBytes(4));
  }

  int? readI64() {
    return bytesToNumber(readBytes(8));
  }

  List<int> readBytes(int len) {
    if (_readerIndex + len <= _capacity) {
      var array = _data.sublist(_readerIndex, _readerIndex + len);
      _readerIndex = _readerIndex + len;
      return array;
    }
    return <int>[];
  }

  Uint8List readUint8List(int len) {
    return Uint8List.fromList(readBytes(len));
  }

  void writeI8(int value) {
    if (_writerIndex == _data.length) {
      _data.add(value);
      autoGrow();
    } else {
      _data[_writerIndex] = value;
    }
    _writerIndex += 1;
  }

  void writeI16(int value) {
    writeBytes(i16ToBytes(value));
  }

  void writeI24(int value) {
    writeBytes(i24ToBytes(value));
  }

  void writeI32(int value) {
    writeBytes(i32ToBytes(value));
  }

  void writeI64(int value) {
    writeBytes(i64ToBytes(value));
  }

  void insertI24(int value) {
    insertBytes(i24ToBytes(value));
  }

  void writeBytes(List<int> bytes) {
    var end = _writerIndex + bytes.length;
    if (_writerIndex == _data.length) {
      _data.addAll(bytes);
    } else {
      _data.replaceRange(_writerIndex, end, bytes);
    }
    _writerIndex = end;
    autoGrow();
  }

  void insertBytes(List<int> bytes) {
    var end = _writerIndex + bytes.length;
    _data.insertAll(_writerIndex, bytes);
    _writerIndex = end;
    autoGrow();
  }

  void writeUint8List(Uint8List data) {
    writeBytes(List.from(data));
  }

  void autoGrow() {
    if (_capacity < _data.length) {
      _capacity = _data.length;
    }
  }

  bool isReadable() {
    return _readerIndex < _capacity;
  }

  int maxReadableBytes() {
    return _capacity - _readerIndex;
  }

  bool isWritable() {
    return _writerIndex < _capacity;
  }

  int maxWritableBytes() {
    return _capacity - _readerIndex;
  }

  void rewind() {
    _readerIndex = 0;
    _writerIndex = 0;
  }

  void resetWriterIndex() {
    _writerIndex = 0;
  }

  void resetReaderIndex() {
    _writerIndex = 0;
  }

  int capacity() {
    return _capacity;
  }

  Uint8List toUint8Array() {
    return Uint8List.fromList(_data);
  }
}

Uint8List i64ToBytes(int value) {
  //because of browser limitations
  int l = value;
  var b = BytesBuilder();
  for (int i = 7; i >= 0; i--) {
    b.addByte(l & 0xFF);

    l >>= 8;
  }
  return Uint8List.fromList(b.toBytes().reversed.toList());
  //return Uint8List(8)..buffer.asByteData().setUint64(0, value, Endian.big);
}

Uint8List i32ToBytes(int value) {
  return Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.big);
}

Uint8List i24ToBytes(int value) {
  var uint8list = Uint8List(4)
    ..buffer.asByteData().setUint32(0, value, Endian.big);
  return uint8list.sublist(1);
}

Uint8List i16ToBytes(int value) {
  return Uint8List(2)..buffer.asByteData().setUint16(0, value, Endian.big);
}

int? bytesToNumber(List<int> data) {
  if (data.isNotEmpty) {
    var value = 0;
    data.forEach((element) => value = (value * 256) + element);
    return value;
  }
  return null;
}
