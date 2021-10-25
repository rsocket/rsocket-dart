import 'dart:mirrors';

import 'reflection.dart';

class RSocketServiceRouter {
  Map<String, dynamic> serviceInstances = {};
  Map<String, InstanceMirror> instanceMirrors = {};

  void addService(dynamic serviceInstance) {
    var rsocketServiceAnnotation = getRSocketServiceAnnotation(serviceInstance);
    if (rsocketServiceAnnotation != null) {
      serviceInstances[rsocketServiceAnnotation.name] = serviceInstance;
      instanceMirrors[rsocketServiceAnnotation.name] = reflect(serviceInstance);
    }
  }

  bool isServiceAvailable(String serviceName) {
    return instanceMirrors.containsKey(serviceName);
  }

  dynamic invokeService(String serviceName, String method, dynamic params) {
    var instanceMirror = instanceMirrors[serviceName];
    if (params == null) {
      return instanceMirror!.invoke(Symbol(method), []).reflectee;
    } else if (params is List) {
      return instanceMirror!.invoke(Symbol(method), params).reflectee;
    } else {
      return instanceMirror!.invoke(Symbol(method), [params]).reflectee;
    }
  }
}
