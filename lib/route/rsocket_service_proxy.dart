import 'package:rsocket/route/reflection.dart';

import '../rsocket.dart';

typedef RSocketCallHandler = dynamic Function(
    RSocketService? rsocketServiceAnnotation,
    String methodName,
    List<dynamic> params);

class RSocketServiceStub {
  RSocketCallHandler? rsocketCallHandler;
  RSocketService? rsocketServiceAnnotation;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    rsocketServiceAnnotation ??= getRSocketServiceAnnotation(this);
    if (rsocketServiceAnnotation == null) {
      throw ('Please add @RSocketService for ${runtimeType}');
    }
    var methodName = invocation.memberName.toString();
    if (methodName.contains('"')) {
      // 'Symbol("missing")'
      methodName = methodName.substring(8, methodName.length - 2);
    }
    if (rsocketCallHandler != null) {
      return rsocketCallHandler!(
          rsocketServiceAnnotation, methodName, invocation.positionalArguments);
    }
    throw ('rsocketCallHandler is null for ${rsocketServiceAnnotation!.name}');
  }
}
