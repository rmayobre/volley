import 'dart:async';

import 'package:volley_api/volley_api.dart';

const _unsupported = 'Workers are not supported on this platform.';

/// Starts an actor. See the io and web implementations.
Future<Actor<I, O>> spawnActorWorker<I extends Message, O extends Message>({
  required FutureOr<I> Function(O) reducer,
  required String workerScript,
  required Map<String, Object?> Function(O) encodeInput,
  required I Function(Map<String, Object?>) decodeOutput,
}) => throw UnimplementedError(_unsupported);

/// Starts a coroutine. See the io and web implementations.
Coroutine<R> launchCoroutineWorker<R>({
  required FutureOr<R> Function() compute,
  required String workerScript,
  required List<Object?> args,
  required R Function(Object?) decodeResult,
}) => throw UnimplementedError(_unsupported);

/// Worker side of an actor. Web only.
void runActorWorker<I extends Message, O extends Message>({
  required FutureOr<I> Function(O) reducer,
  required O Function(Map<String, Object?>) decodeInput,
  required Map<String, Object?> Function(I) encodeOutput,
}) => throw UnimplementedError(_unsupported);

/// Worker side of a coroutine. Web only.
void runCoroutineWorker<R>({
  required FutureOr<R> Function(List<Object?> args) run,
  required Object? Function(R) encodeResult,
}) => throw UnimplementedError(_unsupported);
