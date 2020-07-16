import 'dart:mirrors';

import '../rsocket.dart';

RSocketService getRSocketServiceAnnotation(dynamic instance) {
  final DeclarationMirror clazzDeclaration = reflectClass(instance.runtimeType);
  final classMirror = reflectClass(RSocketService);
  final annotationInstanceMirror = clazzDeclaration.metadata.firstWhere((d) => d.type == classMirror, orElse: () => null);
  if (annotationInstanceMirror == null) {
    print('Annotation is not on this class');
    return null;
  }
  return annotationInstanceMirror.reflectee as RSocketService;
}
