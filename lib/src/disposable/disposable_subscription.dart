import 'dart:async';

import 'disposable.dart';

final class DisposableSubscription<T> implements StreamSubscription<T>, Disposable {

  final StreamSubscription<T> source;

  const DisposableSubscription(this.source);

  @override
  bool get isPaused => source.isPaused;

  @override
  Future<void> dispose() => source.cancel();

  @override
  Future<E> asFuture<E>([E? futureValue]) => source.asFuture(futureValue);

  @override
  Future<void> cancel() => source.cancel();

  @override
  void onData(void Function(T data)? handleData) => source.onData(handleData);

  @override
  void onDone(void Function()? handleDone) => source.onDone(handleDone);

  @override
  void onError(Function? handleError) => source.onError(handleError);

  @override
  void pause([Future<void>? resumeSignal]) => source.pause(resumeSignal);

  @override
  void resume() => source.resume();
}