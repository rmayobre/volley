import 'dart:async';

import '../disposable/disposable.dart';

/// A concurrent computation model that focuses on reusing resources and non-blocking
/// operations. This model is useful for short-lived tasks that too intense to process
/// on the main thread (isolate or web worker).
abstract interface class Coroutine<R> implements Disposable {

  // bool get isDone;

  Future<R> get result;
}