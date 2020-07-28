import 'package:test/test.dart';
import 'package:rsocket/metadata/wellknown_mimetype.dart';

void main() {
  test('mimetypes', () {
    var mimeType = WellKnownMimeType.isWellKnownTypeId(1);
    expect(mimeType, equals(true));
  });
}
