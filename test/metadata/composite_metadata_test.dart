import 'dart:typed_data';

import 'package:rsocket/metadata/composite_metadata.dart';
import 'package:test/test.dart';

void main() {
  test('composite_metadata', () {
    var compositeMetadata = CompositeMetadata.fromEntries([
      MetadataEntry.fromContent(Uint8List(4), 'text/plain'),
      MetadataEntry.fromContent(Uint8List(10), 'text/xml')
    ]);
    var uint8array = compositeMetadata.toUint8Array();
    var compositeMetadata2 = CompositeMetadata.fromU8Array(uint8array);
    compositeMetadata2.forEach((entry) {
      print('mimeType: ' +
          entry.mimeType +
          ', content: ' +
          entry.content.length.toString());
    });
  });
}
