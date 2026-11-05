import 'dart:async';

import '../disposable/disposable.dart';

abstract interface class Coroutine<R> implements Disposable {
  bool get isDone;
  bool get isRunning;
  bool get isCanceled;

  Future<R> get result;
}
