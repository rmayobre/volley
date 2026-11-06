import 'dart:async';

import 'package:volley/volley.dart' as volley;
import 'package:volley/volley.dart' show Singleton;
import 'package:volley_api/volley_api.dart';

/// Starts [reducer] in a dedicated isolate. The web-only parameters are
/// ignored: messages cross the isolate boundary as-is.
Future<Actor<I, O>> spawnActorWorker<I extends Message, O extends Message>({
  required FutureOr<I> Function(O) reducer,
  required String workerScript,
  required Map<String, Object?> Function(O) encodeInput,
  required I Function(Map<String, Object?>) decodeOutput,
}) => volley.actor<I, O>(reducer);

/// Runs [compute] in its own isolate.
Coroutine<R> launchCoroutineWorker<R>({
  required FutureOr<R> Function() compute,
  required String workerScript,
  required List<Object?> args,
  required R Function(Object?) decodeResult,
}) => volley.coroutine<R>(compute);

/// Worker side of an actor. Only meaningful in a web worker.
void runActorWorker<I extends Message, O extends Message>({
  required FutureOr<I> Function(O) reducer,
  required O Function(Map<String, Object?>) decodeInput,
  required Map<String, Object?> Function(I) encodeOutput,
}) => throw UnsupportedError('Worker entrypoints only run in a web worker.');

/// Worker side of a coroutine. Only meaningful in a web worker.
void runCoroutineWorker<R>({
  required FutureOr<R> Function(List<Object?> args) run,
  required Object? Function(R) encodeResult,
}) => throw UnsupportedError('Worker entrypoints only run in a web worker.');

/// Sends [message] to the singleton under [key] and returns its reply. See
/// the io and web implementations.
Future<I>
callSingleton<I extends Message, O extends Message, T extends Singleton<I, O>>({
  required String key,
  required O message,
  required T Function() build,
  required Object? Function(O message) encodeIn,
  required I Function(Object? wire) decodeOut,
}) => Singleton.request<I, O, T>(build, message);
