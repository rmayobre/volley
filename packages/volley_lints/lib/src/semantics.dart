import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// Annotation types declared by `package:volley_workers`.
enum WorkerAnnotation {
  actor('ActorWorker'),
  coroutine('CoroutineWorker'),
  encodable('Encodable'),
  singleton('SingletonWorker');

  const WorkerAnnotation(this.typeName);

  /// Name of the annotation's class (the annotations are constants of it).
  final String typeName;
}

bool _isFromPackage(Element? element, String package) {
  final uri = element?.library?.uri;
  return uri != null &&
      uri.scheme == 'package' &&
      uri.pathSegments.isNotEmpty &&
      uri.pathSegments.first == package;
}

/// Whether [element] is annotated with [annotation] from `volley_workers`.
bool hasWorkerAnnotation(Element element, WorkerAnnotation annotation) {
  for (final meta in element.metadata.annotations) {
    final type = meta.computeConstantValue()?.type;
    final typeElement = type?.element;
    if (typeElement != null &&
        typeElement.name == annotation.typeName &&
        _isFromPackage(typeElement, 'volley_workers')) {
      return true;
    }
  }
  return false;
}

/// Whether [element] carries any `volley_workers` annotation.
bool hasAnyWorkerAnnotation(Element element) =>
    WorkerAnnotation.values.any((a) => hasWorkerAnnotation(element, a));

/// Whether [type] is, or implements, `Message` from `volley_api`.
bool isMessageType(DartType type) {
  if (type is! InterfaceType) return false;
  return _isNamedFrom(type.element, 'Message', 'volley_api') ||
      type.allSupertypes.any(
        (t) => _isNamedFrom(t.element, 'Message', 'volley_api'),
      );
}

/// Whether [element] is a class that is, or implements, `Message`.
bool isMessageClass(InterfaceElement element) =>
    _isNamedFrom(element, 'Message', 'volley_api') ||
    element.allSupertypes.any(
      (t) => _isNamedFrom(t.element, 'Message', 'volley_api'),
    );

bool _isNamedFrom(Element? element, String name, String package) =>
    element != null && element.name == name && _isFromPackage(element, package);

/// The `Singleton<O, I>` supertype of [element] from `package:volley`, if any.
InterfaceType? singletonSupertype(InterfaceElement element) {
  for (final type in element.allSupertypes) {
    if (_isNamedFrom(type.element, 'Singleton', 'volley')) return type;
  }
  return null;
}

/// Whether [type] is `dynamic` or `Object` / `Object?`.
bool isUntyped(DartType type) =>
    type is DynamicType || (type is InterfaceType && type.isDartCoreObject);

/// Why [type] cannot be sent to a worker, or `null` when it can.
///
/// Mirrors `Codec` in `volley_workers_gen`: keep the two in sync.
String? unsupportedWorkerType(DartType type) {
  if (type is VoidType || type is DynamicType) return null;
  if (type is! InterfaceType) {
    return '`${type.getDisplayString()}` cannot be sent to a worker.';
  }
  if (type.isDartCoreObject || type.isDartCoreNull) return null;
  if (type.isDartCoreInt ||
      type.isDartCoreDouble ||
      type.isDartCoreNum ||
      type.isDartCoreString ||
      type.isDartCoreBool) {
    return null;
  }
  final element = type.element;
  if (element.library.uri.toString() == 'dart:typed_data') return null;
  final name = element.name;
  if (element.library.isInSdk &&
      (name == 'BigInt' ||
          name == 'RegExp' ||
          name == 'DateTime' ||
          name == 'Duration')) {
    return null;
  }
  if (element is EnumElement) return null;
  if (type.isDartCoreList || type.isDartCoreSet || type.isDartCoreIterable) {
    return unsupportedWorkerType(type.typeArguments.first);
  }
  if (type.isDartCoreMap) {
    if (!type.typeArguments.first.isDartCoreString) {
      return '`${type.getDisplayString()}`: only maps with String keys can '
          'be sent to a worker.';
    }
    return unsupportedWorkerType(type.typeArguments.last);
  }
  if (element is ClassElement) {
    if (hasWorkerAnnotation(element, WorkerAnnotation.encodable)) return null;
    if (element.allSupertypes.any(
          (t) => _isNamedFrom(t.element, 'MapEncodableMessage', 'volley_api'),
        ) &&
        (element.constructors.any((c) => c.name == 'fromMap') ||
            element.methods.any((m) => m.isStatic && m.name == 'fromMap'))) {
      return null;
    }
  }
  return '`${type.getDisplayString()}` cannot be sent to a worker. Annotate '
      'it with @encodable or implement MapEncodableMessage with a fromMap '
      'factory.';
}

/// The type's `Future<T>` / `FutureOr<T>` value type, or [type] itself.
DartType unwrapFuture(DartType type) {
  if (type is InterfaceType &&
      (type.isDartAsyncFuture || type.isDartAsyncFutureOr)) {
    return type.typeArguments.single;
  }
  return type;
}
