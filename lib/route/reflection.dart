import 'dart:mirrors';

import '../rsocket.dart';
import 'package:collection/collection.dart' show IterableExtension;

RSocketService? getRSocketServiceAnnotation(dynamic instance) {
  final DeclarationMirror clazzDeclaration = reflectClass(instance.runtimeType);
  final classMirror = reflectClass(RSocketService);
  final annotationInstanceMirror = clazzDeclaration.metadata
      .firstWhereOrNull((d) => d.type == classMirror);
  if (annotationInstanceMirror == null) {
    print('Annotation is not on this class');
    return null;
  }
  return annotationInstanceMirror.reflectee as RSocketService?;
}
