import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'codecs.dart';

const _actorChecker = TypeChecker.typeNamedLiterally(
  'ActorWorker',
  inPackage: 'volley_workers',
);
const _singletonChecker = TypeChecker.typeNamedLiterally(
  'SingletonWorker',
  inPackage: 'volley_workers',
);
const _coroutineChecker = TypeChecker.typeNamedLiterally(
  'CoroutineWorker',
  inPackage: 'volley_workers',
);

/// Generates, for one library, everything needed to run its `@actor` and
/// `@coroutine` functions as an isolate or a web worker, and the codecs for
/// its `@encodable` classes.
final class WorkersGenerator extends Generator {
  /// Calls to every `register<Name>()` in the library being generated, run by
  /// each spawn/launch function so workers can reach the page's singletons.
  String _registrations = '';

  /// Returns the body of `<source>.gen.dart` for [library], or `null` when it
  /// has nothing annotated. Singletons are generated first so the spawn and
  /// launch functions can register them.
  @override
  String? generate(LibraryReader library, BuildStep buildStep) {
    final out = <String>[];

    for (final annotated in library.annotatedWith(encodableChecker)) {
      out.add(_message(annotated.element));
    }
    final registrations = <String>[];
    for (final annotated in library.annotatedWith(_singletonChecker)) {
      final (code, register) = _singleton(annotated.element);
      out.add(code);
      registrations.add(register);
    }
    _registrations = registrations.map((r) => '  $r();\n').join();
    for (final annotated in library.annotatedWith(_actorChecker)) {
      out.add(_actor(annotated.element));
    }
    for (final annotated in library.annotatedWith(_coroutineChecker)) {
      out.add(_coroutine(annotated.element));
    }
    if (out.isEmpty) return null;

    return [
      '// ignore_for_file: unused_element, unnecessary_cast, prefer_null_aware_operators\n',
      'Map<String, Object?> _\$volleyAsMap(Object? value) =>\n'
          '    Map<String, Object?>.from(value as Map);\n',
      ...out,
    ].join('\n');
  }

  // --- @encodable ------------------------------------------------------

  /// Codecs for an `@encodable` class: `_$NameToMap` and `_$NameFromMap`,
  /// built from the unnamed constructor's parameters.
  String _message(Element element) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@encodable can only annotate classes.',
        element: element,
      );
    }
    final name = element.name!;
    if (!messageChecker.isAssignableFrom(element)) {
      throw InvalidGenerationSourceError(
        '@encodable `$name` must implement Message.',
        element: element,
      );
    }
    if (element.typeParameters.isNotEmpty) {
      throw InvalidGenerationSourceError(
        '@encodable does not support generic classes.',
        element: element,
      );
    }
    final constructor = element.unnamedConstructor;
    if (constructor == null || element.isAbstract) {
      throw InvalidGenerationSourceError(
        '@encodable needs a concrete class with an unnamed constructor.',
        element: element,
      );
    }
    final codec = Codec();
    final toMap = <String>[];
    final args = <String>[];
    try {
      for (final parameter in constructor.formalParameters) {
        final field = parameter.name!;
        if (field.startsWith('_')) {
          throw InvalidGenerationSourceError(
            '@encodable `$name`: constructor parameter `$field` is '
            'private; use a public parameter name.',
            element: element,
          );
        }
        if (element.getField(field) == null &&
            element.getGetter(field) == null) {
          throw InvalidGenerationSourceError(
            '@encodable `$name`: constructor parameter `$field` has no '
            'matching field or getter named `$field`, so its value cannot '
            'be read when encoding the message.',
            element: element,
          );
        }
        toMap.add("'$field': ${codec.encode(parameter.type, 'value.$field')}");
        final decoded = codec.decode(parameter.type, "map['$field']");
        args.add(parameter.isNamed ? '$field: $decoded' : decoded);
      }
    } on UnsupportedWorkerType catch (e) {
      throw InvalidGenerationSourceError(e.message, element: element);
    }
    final prefix = generatedName(name);
    return '''
Map<String, Object?> ${prefix}ToMap($name value) => {
  ${toMap.join(',\n  ')}${toMap.isEmpty ? '' : ','}
};

$name ${prefix}FromMap(Map<String, Object?> map) => $name(
  ${args.join(',\n  ')}${args.isEmpty ? '' : ','}
);
''';
  }

  // --- @singleton -----------------------------------------------------------

  /// For a `@singleton` class: the `register<Name>` / `request<Name>` code and
  /// the name of the register function.
  (String, String) _singleton(Element element) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@singleton can only annotate classes.',
        element: element,
      );
    }
    final name = element.name!;
    if (element.isAbstract || element.typeParameters.isNotEmpty) {
      throw InvalidGenerationSourceError(
        '@singleton `$name` must be a concrete, non-generic class.',
        element: element,
      );
    }
    final constructor = element.unnamedConstructor;
    if (constructor == null ||
        constructor.formalParameters.any((p) => p.isRequired)) {
      throw InvalidGenerationSourceError(
        '@singleton `$name` needs an unnamed constructor without required '
        'parameters, because the instance is built without arguments.',
        element: element,
      );
    }
    final base = element.allSupertypes.where(
      (t) =>
          t.element.name == 'Singleton' &&
          t.element.library.uri.scheme == 'package' &&
          t.element.library.uri.pathSegments.first == 'volley',
    );
    if (base.isEmpty) {
      throw InvalidGenerationSourceError(
        '@singleton `$name` must extend SerializedSingleton or '
        'ConcurrentSingleton.',
        element: element,
      );
    }
    final input = base.first.typeArguments[1];
    final output = base.first.typeArguments[0];
    final codec = Codec();
    final String decodeIn, encodeIn, decodeOut, encodeOut;
    try {
      decodeIn = codec.decode(input, 'wire');
      encodeIn = codec.encode(input, 'message');
      decodeOut = codec.decode(output, 'wire');
      encodeOut = codec.encode(output, 'message');
    } on UnsupportedWorkerType catch (e) {
      throw InvalidGenerationSourceError(e.message, element: element);
    }
    final i = input.getDisplayString();
    final o = output.getDisplayString();
    final key = '${element.library.uri}#$name';
    final register = 'register$name';
    return (
      '''
/// Makes `$name` reachable from web workers. Called for you by the spawn and
/// launch functions in this library; call it yourself on the page if a worker
/// from another library uses this singleton.
void $register() => registerSingleton<$o, $i, $name>(
  key: '$key',
  build: $name.new,
  decodeIn: (Object? wire) => $decodeIn,
  encodeOut: ($o message) => $encodeOut,
);

/// Sends [message] to `$name` and returns its reply. Works on the page, in a
/// web worker (the page owns the instance) and on the VM.
Future<$o> request$name($i message) {
  $register();
  return callSingleton<$o, $i, $name>(
    key: '$key',
    message: message,
    build: $name.new,
    encodeIn: ($i message) => $encodeIn,
    decodeOut: (Object? wire) => $decodeOut,
  );
}
''',
      register,
    );
  }

  // --- @actor ---------------------------------------------------------------

  /// `spawn<Name>` and `<name>WorkerMain` for an `@actor` function.
  String _actor(Element element) {
    final function = _topLevelFunction(element, '@actor');
    final name = function.name!;
    final parameters = function.formalParameters;
    if (parameters.length != 1 || !parameters.single.isRequiredPositional) {
      throw InvalidGenerationSourceError(
        '@actor functions take exactly one required positional parameter: a '
        'Message.',
        element: function,
      );
    }
    final input = parameters.single.type;
    final output = _unwrap(function.returnType);
    for (final type in [input, output]) {
      if (type is! InterfaceType ||
          !messageChecker.isAssignableFromType(type)) {
        throw InvalidGenerationSourceError(
          '@actor functions must take a Message and return a Message '
          '(optionally in a Future); found `$type`.',
          element: function,
        );
      }
    }
    final codec = Codec();
    final String encodeInput, decodeInput, encodeOutput, decodeOutput;
    try {
      encodeInput = codec.encode(input, 'message');
      decodeInput = codec.decode(input, 'map');
      encodeOutput = codec.encode(output, 'message');
      decodeOutput = codec.decode(output, 'map');
    } on UnsupportedWorkerType catch (e) {
      throw InvalidGenerationSourceError(e.message, element: function);
    }
    final i = input.getDisplayString();
    final o = output.getDisplayString();
    final upper = _capitalize(name);
    return '''
/// Starts `$name` as an actor: an isolate on the VM, a web worker on the web
/// (compiled from an entrypoint that calls `${name}WorkerMain`).
///
/// Send `$i` on the channel; receive `$o`.
Future<Actor<$o, $i>> spawn$upper({
  String workerScript = '$name.worker.js',
}) {
$_registrations  return spawnActorWorker<$o, $i>(
    reducer: $name,
    workerScript: workerScript,
    encodeInput: ($i message) => $encodeInput,
    decodeOutput: (Map<String, Object?> map) => $decodeOutput,
  );
}

/// Web worker entrypoint for `$name`. Call it from the `main` of the worker
/// you compile with `dart compile js`.
void ${name}WorkerMain() => runActorWorker<$o, $i>(
  reducer: $name,
  decodeInput: (Map<String, Object?> map) => $decodeInput,
  encodeOutput: ($o message) => $encodeOutput,
);
''';
  }

  // --- @coroutine -----------------------------------------------------------

  /// `launch<Name>` and `<name>WorkerMain` for a `@coroutine` function.
  String _coroutine(Element element) {
    final function = _topLevelFunction(element, '@coroutine');
    final name = function.name!;
    final parameters = function.formalParameters;
    if (parameters.any((p) => !p.isRequiredPositional)) {
      throw InvalidGenerationSourceError(
        '@coroutine functions only support required positional parameters.',
        element: function,
      );
    }
    final result = _unwrap(function.returnType);
    final codec = Codec();
    final signature = <String>[];
    final callArgs = <String>[];
    final encodedArgs = <String>[];
    final decodedArgs = <String>[];
    final String encodeResult, decodeResult;
    try {
      for (var index = 0; index < parameters.length; index++) {
        final parameter = parameters[index];
        final argument = 'arg$index';
        signature.add('${parameter.type.getDisplayString()} $argument');
        callArgs.add(argument);
        encodedArgs.add(codec.encode(parameter.type, argument));
        decodedArgs.add(codec.decode(parameter.type, 'args[$index]'));
      }
      encodeResult = codec.encode(result, 'value');
      decodeResult = codec.decode(result, 'value');
    } on UnsupportedWorkerType catch (e) {
      throw InvalidGenerationSourceError(e.message, element: function);
    }
    final r = result.getDisplayString();
    final upper = _capitalize(name);
    final params = [...signature, "{String workerScript = '$name.worker.js'}"];
    return '''
/// Runs `$name` as a coroutine: in an isolate on the VM, in a web worker on
/// the web (compiled from an entrypoint that calls `${name}WorkerMain`).
Coroutine<$r> launch$upper(${params.join(', ')}) {
$_registrations  return launchCoroutineWorker<$r>(
    compute: () => $name(${callArgs.join(', ')}),
    workerScript: workerScript,
    args: [${encodedArgs.join(', ')}],
    decodeResult: (Object? value) => $decodeResult,
  );
}

/// Web worker entrypoint for `$name`. Call it from the `main` of the worker
/// you compile with `dart compile js`.
void ${name}WorkerMain() => runCoroutineWorker<$r>(
  run: (List<Object?> args) => $name(${decodedArgs.join(', ')}),
  encodeResult: ($r value) => $encodeResult,
);
''';
  }

  // --- helpers --------------------------------------------------------------

  /// [element] as a non-generic top-level function, or an
  /// [InvalidGenerationSourceError] naming [annotation].
  ExecutableElement _topLevelFunction(Element element, String annotation) {
    if (element is! TopLevelFunctionElement) {
      throw InvalidGenerationSourceError(
        '$annotation can only annotate top-level functions.',
        element: element,
      );
    }
    if (element.typeParameters.isNotEmpty) {
      throw InvalidGenerationSourceError(
        '$annotation functions cannot be generic.',
        element: element,
      );
    }
    return element;
  }

  /// `Future<T>` / `FutureOr<T>` -> `T`; anything else is returned as-is.
  /// A function's value type: `Future<T>` / `FutureOr<T>` -> `T`.
  DartType _unwrap(DartType type) {
    if (type is InterfaceType &&
        (type.isDartAsyncFuture || type.isDartAsyncFutureOr)) {
      return type.typeArguments.single;
    }
    return type;
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
