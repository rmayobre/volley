// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'workers.dart';

// **************************************************************************
// WorkersGenerator
// **************************************************************************

// ignore_for_file: unused_element, unnecessary_cast, prefer_null_aware_operators

Map<String, Object?> _$volleyAsMap(Object? value) =>
    Map<String, Object?>.from(value as Map);

Map<String, Object?> _$AnalyzeRequestToMap(AnalyzeRequest value) => {
  'limit': value.limit,
};

AnalyzeRequest _$AnalyzeRequestFromMap(Map<String, Object?> map) =>
    AnalyzeRequest((map['limit'] as int));

Map<String, Object?> _$AnalyzeReportToMap(AnalyzeReport value) => {
  'limit': value.limit,
  'count': value.count,
  'largest': value.largest,
  'milliseconds': value.milliseconds,
  'runs': value.runs,
};

AnalyzeReport _$AnalyzeReportFromMap(Map<String, Object?> map) => AnalyzeReport(
  limit: (map['limit'] as int),
  count: (map['count'] as int),
  largest: (map['largest'] as int),
  milliseconds: (map['milliseconds'] as int),
  runs: (map['runs'] as int),
);

Map<String, Object?> _$RunStartedToMap(RunStarted value) => {};

RunStarted _$RunStartedFromMap(Map<String, Object?> map) => RunStarted();

Map<String, Object?> _$RunCountToMap(RunCount value) => {'runs': value.runs};

RunCount _$RunCountFromMap(Map<String, Object?> map) =>
    RunCount((map['runs'] as int));

/// Makes `RunLog` reachable from web workers. Called for you by the spawn and
/// launch functions in this library; call it yourself on the page if a worker
/// from another library uses this singleton.
void registerRunLog() => registerSingleton<RunCount, RunStarted, RunLog>(
  key: 'package:flutter_workers/workers.dart#RunLog',
  build: RunLog.new,
  decodeIn: (Object? wire) => _$RunStartedFromMap(_$volleyAsMap(wire)),
  encodeOut: (RunCount message) => _$RunCountToMap(message),
);

/// Sends [message] to `RunLog` and returns its reply. Works on the page, in a
/// web worker (the page owns the instance) and on the VM.
Future<RunCount> requestRunLog(RunStarted message) {
  registerRunLog();
  return callSingleton<RunCount, RunStarted, RunLog>(
    key: 'package:flutter_workers/workers.dart#RunLog',
    message: message,
    build: RunLog.new,
    encodeIn: (RunStarted message) => _$RunStartedToMap(message),
    decodeOut: (Object? wire) => _$RunCountFromMap(_$volleyAsMap(wire)),
  );
}

/// Starts `analyze` as an actor: an isolate on the VM, a web worker on the web
/// (compiled from an entrypoint that calls `analyzeWorkerMain`).
///
/// Send `AnalyzeRequest` on the channel; receive `AnalyzeReport`.
Future<Actor<AnalyzeReport, AnalyzeRequest>> spawnAnalyze({
  String workerScript = 'analyze.worker.js',
}) {
  registerRunLog();
  return spawnActorWorker<AnalyzeReport, AnalyzeRequest>(
    reducer: analyze,
    workerScript: workerScript,
    encodeInput: (AnalyzeRequest message) => _$AnalyzeRequestToMap(message),
    decodeOutput:
        (Map<String, Object?> map) =>
            _$AnalyzeReportFromMap(_$volleyAsMap(map)),
  );
}

/// Web worker entrypoint for `analyze`. Call it from the `main` of the worker
/// you compile with `dart compile js`.
void analyzeWorkerMain() => runActorWorker<AnalyzeReport, AnalyzeRequest>(
  reducer: analyze,
  decodeInput:
      (Map<String, Object?> map) => _$AnalyzeRequestFromMap(_$volleyAsMap(map)),
  encodeOutput: (AnalyzeReport message) => _$AnalyzeReportToMap(message),
);

/// Runs `countPrimes` as a coroutine: in an isolate on the VM, in a web worker on
/// the web (compiled from an entrypoint that calls `countPrimesWorkerMain`).
Coroutine<int> launchCountPrimes(
  int arg0, {
  String workerScript = 'countPrimes.worker.js',
}) {
  registerRunLog();
  return launchCoroutineWorker<int>(
    compute: () => countPrimes(arg0),
    workerScript: workerScript,
    args: [arg0],
    decodeResult: (Object? value) => (value as int),
  );
}

/// Web worker entrypoint for `countPrimes`. Call it from the `main` of the worker
/// you compile with `dart compile js`.
void countPrimesWorkerMain() => runCoroutineWorker<int>(
  run: (List<Object?> args) => countPrimes((args[0] as int)),
  encodeResult: (int value) => value,
);
