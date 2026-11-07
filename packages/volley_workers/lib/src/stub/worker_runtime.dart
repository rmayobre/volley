import 'dart:async';

import 'package:volley/volley.dart' show Singleton;
import 'package:volley_api/volley_api.dart';

const _unsupported = 'Workers are not supported on this platform.';

/// Starts an actor for the generated `spawn<Name>` function.
///
/// * [reducer]: the annotated `@actor` function.
/// * [workerScript]: URL of the compiled web worker script. Web only; the VM
///   ignores it.
/// * [encodeInput] / [decodeOutput]: convert messages to and from the
///   JS-safe wire form. Web only; the VM sends messages as-is.
///
/// On the VM this is an isolate actor (see `volley`'s `actor`). On the web it
/// starts a `Worker` and completes once the worker reports it is ready.
Future<Actor<I, O>> spawnActorWorker<I extends Message, O extends Message>({
  required FutureOr<I> Function(O) reducer,
  required String workerScript,
  required Map<String, Object?> Function(O) encodeInput,
  required I Function(Map<String, Object?>) decodeOutput,
}) => throw UnimplementedError(_unsupported);

/// Starts a coroutine for the generated `launch<Name>` function.
///
/// * [compute]: runs the annotated `@coroutine` function with its arguments.
///   Used on the VM, where it runs in a `volley` coroutine isolate.
/// * [workerScript]: URL of the compiled web worker script. Web only.
/// * [args] / [decodeResult]: the arguments in wire form and the converter
///   for the result. Web only.
///
/// On the web, disposing the returned coroutine terminates the worker and
/// fails `result` with `CoroutineDisposedException`.
Coroutine<R> launchCoroutineWorker<R>({
  required FutureOr<R> Function() compute,
  required String workerScript,
  required List<Object?> args,
  required R Function(Object?) decodeResult,
}) => throw UnimplementedError(_unsupported);

/// Worker side of an actor: call it (through the generated
/// `<name>WorkerMain`) from the web worker's `main`.
///
/// Decodes each incoming message with [decodeInput], runs [reducer], and
/// posts [encodeOutput] of the result back, one message at a time in order.
/// Web only; throws `UnsupportedError` elsewhere.
void runActorWorker<I extends Message, O extends Message>({
  required FutureOr<I> Function(O) reducer,
  required O Function(Map<String, Object?>) decodeInput,
  required Map<String, Object?> Function(I) encodeOutput,
}) => throw UnimplementedError(_unsupported);

/// Worker side of a coroutine: call it (through the generated
/// `<name>WorkerMain`) from the web worker's `main`.
///
/// Waits for the start message, runs [run] with the decoded arguments, and
/// posts [encodeResult] of the value, or the error as text. Web only; throws
/// `UnsupportedError` elsewhere.
void runCoroutineWorker<R>({
  required FutureOr<R> Function(List<Object?> args) run,
  required Object? Function(R) encodeResult,
}) => throw UnimplementedError(_unsupported);

/// Sends [message] to the singleton [key] and returns the reply to that call.
///
/// Backs the generated `request<Name>` function.
///
/// * [build]: constructs the singleton the first time it is needed.
/// * [encodeIn] / [decodeOut]: convert to and from the wire form. Used only
///   when the call runs inside a web worker.
///
/// On the VM and on a web page this calls the singleton directly. Inside a web
/// worker it asks the page, which owns the instance, and fails if the page has
/// no singleton registered under [key].
Future<I>
callSingleton<I extends Message, O extends Message, T extends Singleton<I, O>>({
  required String key,
  required O message,
  required T Function() build,
  required Object? Function(O message) encodeIn,
  required I Function(Object? wire) decodeOut,
}) => throw UnimplementedError(_unsupported);
