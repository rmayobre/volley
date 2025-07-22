import 'dart:async';

import '../disposable/disposable.dart';

typedef Computation<R> = FutureOr<R> Function();

abstract interface class Agent implements Disposable {

  Future<R> compute<R>(Computation<R> computation);
}