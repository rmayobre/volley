// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'workers.dart';

// **************************************************************************
// WorkersGenerator
// **************************************************************************

// ignore_for_file: unused_element, unnecessary_cast, prefer_null_aware_operators

Map<String, Object?> _$volleyAsMap(Object? value) =>
    Map<String, Object?>.from(value as Map);

Map<String, Object?> _$PingToMap(Ping value) => {
  'text': value.text,
  'numbers': value.numbers.map((v0) => v0).toList(),
  'at': ((DateTime? v2) => v2 == null ? null : v2.millisecondsSinceEpoch)(
    value.at,
  ),
};

Ping _$PingFromMap(Map<String, Object?> map) => Ping(
  (map['text'] as String),
  numbers: (map['numbers'] as List).map((v1) => (v1 as int)).toList(),
  at: ((Object? v3) =>
      v3 == null ? null : DateTime.fromMillisecondsSinceEpoch(v3 as int))(
    map['at'],
  ),
);

Map<String, Object?> _$PongToMap(Pong value) => {
  'text': value.text,
  'total': value.total,
};

Pong _$PongFromMap(Map<String, Object?> map) =>
    Pong((map['text'] as String), (map['total'] as int));

/// Starts `echo` as an actor: an isolate on the VM, a web worker on the web
/// (compiled from an entrypoint that calls `echoWorkerMain`).
///
/// Send `Ping` on the channel; receive `Pong`.
Future<Actor<Pong, Ping>> spawnEcho({String workerScript = 'echo.worker.js'}) =>
    spawnActorWorker<Pong, Ping>(
      reducer: echo,
      workerScript: workerScript,
      encodeInput: (Ping message) => _$PingToMap(message),
      decodeOutput:
          (Map<String, Object?> map) => _$PongFromMap(_$volleyAsMap(map)),
    );

/// Web worker entrypoint for `echo`. Call it from the `main` of the worker
/// you compile with `dart compile js`.
void echoWorkerMain() => runActorWorker<Pong, Ping>(
  reducer: echo,
  decodeInput: (Map<String, Object?> map) => _$PingFromMap(_$volleyAsMap(map)),
  encodeOutput: (Pong message) => _$PongToMap(message),
);

/// Runs `sum` as a coroutine: in an isolate on the VM, in a web worker on
/// the web (compiled from an entrypoint that calls `sumWorkerMain`).
Coroutine<int> launchSum(
  List<int> arg0,
  int arg1, {
  String workerScript = 'sum.worker.js',
}) => launchCoroutineWorker<int>(
  compute: () => sum(arg0, arg1),
  workerScript: workerScript,
  args: [arg0.map((v0) => v0).toList(), arg1],
  decodeResult: (Object? value) => (value as int),
);

/// Web worker entrypoint for `sum`. Call it from the `main` of the worker
/// you compile with `dart compile js`.
void sumWorkerMain() => runCoroutineWorker<int>(
  run:
      (List<Object?> args) => sum(
        (args[0] as List).map((v1) => (v1 as int)).toList(),
        (args[1] as int),
      ),
  encodeResult: (int value) => value,
);
