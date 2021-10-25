class StreamIdSupplier {
  static int MASK = 0x7FFFFFFF;
  int streamId = 0;
  late int initialValue;

  StreamIdSupplier();

  StreamIdSupplier.streamId(int streamId) {
    this.streamId = streamId;
    initialValue = streamId;
  }

  static StreamIdSupplier clientSupplier() {
    return StreamIdSupplier.streamId(-1);
  }

  static StreamIdSupplier serverSupplier() {
    return StreamIdSupplier.streamId(0);
  }

  int? nextStreamId(Map<int, dynamic> streamIds) {
    var nextStreamId;
    do {
      streamId += 2;
      //Dart int range -2**53 to 2**53
      if (streamId > StreamIdSupplier.MASK) {
        streamId = initialValue + 2;
      }
      nextStreamId = streamId;
    } while (nextStreamId == 0 || streamIds.containsKey(nextStreamId));
    return nextStreamId;
  }
}
