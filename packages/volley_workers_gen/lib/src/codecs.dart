import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

const volleyMessageChecker = TypeChecker.typeNamedLiterally(
  'VolleyMessage',
  inPackage: 'volley_workers',
);

const mapEncodableChecker = TypeChecker.typeNamedLiterally(
  'MapEncodableMessage',
  inPackage: 'volley_api',
);

const messageChecker = TypeChecker.typeNamedLiterally(
  'Message',
  inPackage: 'volley_api',
);

/// Thrown for types the generator cannot send to a worker.
final class UnsupportedWorkerType implements Exception {
  final String message;
  UnsupportedWorkerType(this.message);
  @override
  String toString() => message;
}

String generatedName(String className) => '_\$$className';

/// Builds the Dart expressions that convert values of [type] to and from the
/// JS-safe form (null, bool, num, String, List, Map, typed data) that web
/// workers can transfer.
final class Codec {
  var _depth = 0;

  /// Expression that converts [expr] (a value of [type]) to its wire form.
  String encode(DartType type, String expr) {
    if (type.nullabilitySuffix == NullabilitySuffix.question) {
      final v = _next();
      final inner = _encodeNonNull(type, v);
      return '((${type.getDisplayString()} $v) => '
          '$v == null ? null : $inner)($expr)';
    }
    return _encodeNonNull(type, expr);
  }

  /// Expression that converts [expr] (an `Object?` wire value) to [type].
  String decode(DartType type, String expr) {
    if (type.nullabilitySuffix == NullabilitySuffix.question) {
      final v = _next();
      final inner = _decodeNonNull(type, v);
      return '((Object? $v) => $v == null ? null : $inner)($expr)';
    }
    return _decodeNonNull(type, expr);
  }

  String _next() => 'v${_depth++}';

  bool _isTypedData(InterfaceType type) =>
      type.element.library.uri.toString() == 'dart:typed_data';

  String _encodeNonNull(DartType type, String expr) {
    if (type is VoidType) return 'null';
    if (type is DynamicType || type.isDartCoreObject) return expr;
    if (type.isDartCoreNull) return 'null';
    if (type is! InterfaceType) {
      throw UnsupportedWorkerType('`$type` cannot be sent to a worker.');
    }
    if (type.isDartCoreInt ||
        type.isDartCoreDouble ||
        type.isDartCoreNum ||
        type.isDartCoreString ||
        type.isDartCoreBool ||
        _isTypedData(type)) {
      return expr;
    }
    final name = type.element.name;
    if (name == 'BigInt') return 'bigIntToMap($expr)';
    if (name == 'RegExp') return 'regExpToMap($expr)';
    if (name == 'DateTime') return '$expr.millisecondsSinceEpoch';
    if (name == 'Duration') return '$expr.inMicroseconds';
    final element = type.element;
    if (element is EnumElement) return '$expr.name';
    if (type.isDartCoreList || type.isDartCoreSet || type.isDartCoreIterable) {
      final v = _next();
      final item = _encodeAt(type.typeArguments.first, v);
      return '$expr.map(($v) => $item).toList()';
    }
    if (type.isDartCoreMap) {
      final key = type.typeArguments.first;
      if (!key.isDartCoreString) {
        throw UnsupportedWorkerType(
          '`$type`: only maps with String keys can be sent to a worker.',
        );
      }
      final v = _next();
      final value = _encodeAt(type.typeArguments.last, v);
      return '$expr.map((k, $v) => MapEntry(k, $value))';
    }
    if (element is ClassElement) {
      if (volleyMessageChecker.hasAnnotationOf(element)) {
        return '${generatedName(name!)}ToMap($expr)';
      }
      if (mapEncodableChecker.isSuperOf(element)) return '$expr.toMap()';
    }
    throw UnsupportedWorkerType(
      '`$type` cannot be sent to a worker. Annotate it with @volleyMessage or '
      'implement MapEncodableMessage with a fromMap factory.',
    );
  }

  String _encodeAt(DartType type, String v) => encode(type, v);

  String _decodeNonNull(DartType type, String expr) {
    if (type is VoidType) return 'null';
    if (type is DynamicType) return expr;
    if (type.isDartCoreObject) return '$expr as Object';
    if (type.isDartCoreNull) return 'null';
    if (type is! InterfaceType) {
      throw UnsupportedWorkerType('`$type` cannot be sent to a worker.');
    }
    final display = type.getDisplayString();
    if (type.isDartCoreInt ||
        type.isDartCoreDouble ||
        type.isDartCoreNum ||
        type.isDartCoreString ||
        type.isDartCoreBool ||
        _isTypedData(type)) {
      return '($expr as $display)';
    }
    final name = type.element.name;
    if (name == 'BigInt') return 'bigIntFromMap($expr)';
    if (name == 'RegExp') return 'regExpFromMap(_\$volleyAsMap($expr))';
    if (name == 'DateTime') {
      return 'DateTime.fromMillisecondsSinceEpoch($expr as int)';
    }
    if (name == 'Duration') return 'Duration(microseconds: $expr as int)';
    final element = type.element;
    if (element is EnumElement) {
      return '$display.values.byName($expr as String)';
    }
    if (type.isDartCoreList || type.isDartCoreSet || type.isDartCoreIterable) {
      final v = _next();
      final item = decode(type.typeArguments.first, v);
      final suffix = type.isDartCoreSet ? '.toSet()' : '.toList()';
      return '($expr as List).map(($v) => $item)$suffix';
    }
    if (type.isDartCoreMap) {
      final v = _next();
      final value = decode(type.typeArguments.last, v);
      final valueType = type.typeArguments.last.getDisplayString();
      return '($expr as Map).map((k, $v) => MapEntry<String, $valueType>(k as String, $value))';
    }
    if (element is ClassElement) {
      if (volleyMessageChecker.hasAnnotationOf(element)) {
        return '${generatedName(name!)}FromMap(_\$volleyAsMap($expr))';
      }
      if (mapEncodableChecker.isSuperOf(element)) {
        final hasFromMap =
            element.constructors.any((c) => c.name == 'fromMap') ||
            element.methods.any((m) => m.isStatic && m.name == 'fromMap');
        if (hasFromMap) return '$display.fromMap(_\$volleyAsMap($expr))';
      }
    }
    throw UnsupportedWorkerType(
      '`$type` cannot be sent to a worker. Annotate it with @volleyMessage or '
      'implement MapEncodableMessage with a fromMap factory.',
    );
  }
}
