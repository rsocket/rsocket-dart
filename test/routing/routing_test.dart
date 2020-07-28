import 'dart:mirrors';

import 'package:rsocket/route/rsocket_service_router.dart';
import 'package:rsocket/rsocket.dart';
import 'package:test/test.dart';

@RSocketService('com.example.UserService', '1.0.0')
class UserService {
  String findNick(int id) {
    return 'nick: ${id}';
  }
}

void main() {
  test('reflectionAnnotation', () {
    var router = RSocketServiceRouter();
    router.addService(UserService());
    var result = router.invokeService('com.example.UserService', 'findNick', 1);
    print('result: ${result}');
  });

  test('reflectionCall', () {
    var userService = UserService();
    var reflectedClass = reflect(userService);
    var result = reflectedClass.invoke(Symbol('findNick'), [1]);
    print(result.reflectee);
  });
}
