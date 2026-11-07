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

Map<String, Object?> _$AddToMap(Add value) => {'amount': value.amount};

Add _$AddFromMap(Map<String, Object?> map) => Add((map['amount'] as int));

Map<String, Object?> _$TotalToMap(Total value) => {'value': value.value};

Total _$TotalFromMap(Map<String, Object?> map) => Total((map['value'] as int));

/// Makes `Counter` reachable from web workers. Called for you by the spawn and
/// launch functions in this library; call it yourself on the page if a worker
/// from another library uses this singleton.
void registerCounter() => registerSingleton<Total, Add, Counter>(
  key: 'package:volley_workers_gen/sample.dart#Counter',
  build: Counter.new,
  decodeIn: (Object? wire) => _$AddFromMap(_$volleyAsMap(wire)),
  encodeOut: (Total message) => _$TotalToMap(message),
);

/// Sends [message] to `Counter` and returns its reply. Works on the page, in a
/// web worker (the page owns the instance) and on the VM.
Future<Total> requestCounter(Add message) {
  registerCounter();
  return callSingleton<Total, Add, Counter>(
    key: 'package:volley_workers_gen/sample.dart#Counter',
    message: message,
    build: Counter.new,
    encodeIn: (Add message) => _$AddToMap(message),
    decodeOut: (Object? wire) => _$TotalFromMap(_$volleyAsMap(wire)),
  );
}

/// Starts `echo` as an actor: an isolate on the VM, a web worker on the web
/// (compiled from an entrypoint that calls `echoWorkerMain`).
///
/// Send `Ping` on the channel; receive `Pong`.
Future<Actor<Pong, Ping>> spawnEcho({String workerScript = 'echo.worker.js'}) {
  registerCounter();
  return spawnActorWorker<Pong, Ping>(
    reducer: echo,
    workerScript: workerScript,
    encodeInput: (Ping message) => _$PingToMap(message),
    decodeOutput:
        (Map<String, Object?> map) => _$PongFromMap(_$volleyAsMap(map)),
  );
}

/// Web worker entrypoint for `echo`. Call it from the `main` of the worker
/// you compile with `dart compile js`.
void echoWorkerMain() => runActorWorker<Pong, Ping>(
  reducer: echo,
  decodeInput: (Map<String, Object?> map) => _$PingFromMap(_$volleyAsMap(map)),
  encodeOutput: (Pong message) => _$PongToMap(message),
);

/// Starts `accumulate` as an actor: an isolate on the VM, a web worker on the web
/// (compiled from an entrypoint that calls `accumulateWorkerMain`).
///
/// Send `Add` on the channel; receive `Total`.
Future<Actor<Total, Add>> spawnAccumulate({
  String workerScript = 'accumulate.worker.js',
}) {
  registerCounter();
  return spawnActorWorker<Total, Add>(
    reducer: accumulate,
    workerScript: workerScript,
    encodeInput: (Add message) => _$AddToMap(message),
    decodeOutput:
        (Map<String, Object?> map) => _$TotalFromMap(_$volleyAsMap(map)),
  );
}

/// Web worker entrypoint for `accumulate`. Call it from the `main` of the worker
/// you compile with `dart compile js`.
void accumulateWorkerMain() => runActorWorker<Total, Add>(
  reducer: accumulate,
  decodeInput: (Map<String, Object?> map) => _$AddFromMap(_$volleyAsMap(map)),
  encodeOutput: (Total message) => _$TotalToMap(message),
);

/// Runs `sum` as a coroutine: in an isolate on the VM, in a web worker on
/// the web (compiled from an entrypoint that calls `sumWorkerMain`).
Coroutine<int> launchSum(
  List<int> arg0,
  int arg1, {
  String workerScript = 'sum.worker.js',
}) {
  registerCounter();
  return launchCoroutineWorker<int>(
    compute: () => sum(arg0, arg1),
    workerScript: workerScript,
    args: [arg0.map((v0) => v0).toList(), arg1],
    decodeResult: (Object? value) => (value as int),
  );
}

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

/// Runs `bump` as a coroutine: in an isolate on the VM, in a web worker on
/// the web (compiled from an entrypoint that calls `bumpWorkerMain`).
Coroutine<int> launchBump(int arg0, {String workerScript = 'bump.worker.js'}) {
  registerCounter();
  return launchCoroutineWorker<int>(
    compute: () => bump(arg0),
    workerScript: workerScript,
    args: [arg0],
    decodeResult: (Object? value) => (value as int),
  );
}

/// Web worker entrypoint for `bump`. Call it from the `main` of the worker
/// you compile with `dart compile js`.
void bumpWorkerMain() => runCoroutineWorker<int>(
  run: (List<Object?> args) => bump((args[0] as int)),
  encodeResult: (int value) => value,
);
