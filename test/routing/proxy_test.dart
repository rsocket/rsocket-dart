import 'package:rsocket/route/rsocket_service_proxy.dart';
import 'package:rsocket/rsocket.dart';
import 'package:test/test.dart';

@RSocketService('com.example.UserService', '1.0.0')
class UserService extends RSocketServiceStub {
  String missing(int age, String name);

  String getName() {
    return 'rsocket';
  }
}

void main() {
  test('proxy_call', () {
    RSocketCallHandler handler = (RSocketService? rsocketServiceAnnotation,
        String methodName, List<dynamic> params) {
      return 'rsocket';
    };
    var userService = UserService()..rsocketCallHandler = handler;
    var result = userService.missing(1, 'name');
    expect(result, equals('rsocket'));
  });
}
