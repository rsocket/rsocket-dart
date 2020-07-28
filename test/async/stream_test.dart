import 'dart:async';

import 'package:test/test.dart';

Stream<String> names() async* {
  yield 'first';
  yield 'second';
}

void main() {
  test('stream', () {
    names().map((item) => item + '!').listen((name) {
      print(name);
    });
  });

  test('StreamController', () {
    var controller = StreamController();
    controller.stream.listen((event) {
      print(event);
    });
    controller.add('first');
    controller.add('second');
    controller.close().then((value) => {});
  });
}
