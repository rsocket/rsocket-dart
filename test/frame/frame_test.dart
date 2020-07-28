import 'package:rsocket/frame/frame.dart';
import 'package:rsocket/io/bytes.dart';
import 'package:test/test.dart';

void main() {
  test('RSocketHeaderTest', () {
    var buffer = RSocketByteBuffer();
    buffer.writeI24(23); // frame length
    buffer.writeI32(0); //stream id
    buffer.writeI8(0x0A << 2); // payload frame
    buffer.writeI8(0); //flags
    buffer.rewind();
    var header = RSocketHeader.fromBuffer(buffer);
    print(header.type);
    expect(header.type, equals(0x0A));
    print(header.metaPresent);
    expect(header.metaPresent, equals(false));
  });

  test('setupPayloadFrame', () {
    var bytes = FrameCodec.encodeSetupFrame(20, 90,
        'message/x.rsocket.composite-metadata.v0', 'application/json', null);
    print(bytes);
    print(bytes.length);
  });
}
