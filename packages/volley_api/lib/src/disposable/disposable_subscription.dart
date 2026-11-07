import 'dart:async';

import 'disposable.dart';

/// A [StreamSubscription] that is also a [Disposable]; disposing cancels it.
///
/// Create one with `StreamSubscription.asDisposable()`.
final class DisposableSubscription<T>
    implements StreamSubscription<T>, Disposable {
  /// The wrapped subscription; every call is delegated to it.
  final StreamSubscription<T> source;

  DisposableSubscription(this.source);

  @override
  Future<void> cancel() => source.cancel();

  @override
  Future<void> dispose() => source.cancel();

  @override
  void onData(void Function(T event)? onData) => source.onData(onData);

  @override
  void onDone(void Function()? onDone) => source.onDone(onDone);

  @override
  void onError(Function? onError) => source.onError(onError);

  @override
  void pause([Future<void>? resumeSignal]) => source.pause(resumeSignal);

  @override
  void resume() => source.resume();

  @override
  bool get isPaused => source.isPaused;

  @override
  Future<E> asFuture<E>([E? futureValue]) => source.asFuture(futureValue);
}
