import 'package:rsocket/core/stream_id_supplier.dart';
import 'package:test/test.dart';

void main() {
  test('StreamIdSupplier', () {
    var streamIds = <int, dynamic>{1: 'demo', 3: 'demo'};
    var streamIdSupplier = StreamIdSupplier.clientSupplier();
    var nextStreamId = streamIdSupplier.nextStreamId(streamIds);
    expect(nextStreamId, equals(5));
    print(nextStreamId);
  });
}
