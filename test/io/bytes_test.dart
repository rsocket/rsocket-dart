import 'package:test/test.dart';

import 'package:rsocket/io/bytes.dart';

void main() {
  test('int32toBytes', () {
    var buffer = RSocketByteBuffer();
    buffer.writeI8(1);
    buffer.writeI16(33);
    buffer.rewind();
    expect(buffer.readI8(), equals(1));
    expect(buffer.readI16(), equals(33));
  });

  test('resetFrameLength', () {
    var buffer = RSocketByteBuffer();
    buffer.writeI24(0);
    buffer.writeI32(0);
    buffer.writeI16(10);
    buffer.rewind();
    buffer.writeI24(buffer.capacity() - 3);
    print(buffer.toUint8Array());
  });
}
