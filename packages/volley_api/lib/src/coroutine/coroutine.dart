import 'dart:async';

import '../disposable/disposable.dart';

/// A handle to one-shot work running concurrently, producing a value of type
/// [R].
///
/// Disposing a running coroutine cancels it; [result] then completes with a
/// `CoroutineDisposedException`.
abstract interface class Coroutine<R> implements Disposable {
  /// Whether the work finished and its [result] is available.
  bool get isDone;

  /// Whether the work is still in progress (neither done nor canceled).
  bool get isRunning;

  /// Whether the coroutine was canceled (disposed) before it completed.
  bool get isCanceled;

  /// The value the work produced, or the error it failed with.
  Future<R> get result;
}
