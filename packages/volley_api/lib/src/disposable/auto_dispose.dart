import 'dart:async';

import 'disposable.dart';

/// A block of work, sync or async, yielding [R].
typedef Procedure<R> = FutureOr<R> Function();

/// A block of work that is handed the resource it should use.
typedef Usage<T, R> = FutureOr<R> Function(Disposable);

/// Runs [process] and then disposes [disposable], whether [process] returns or
/// throws. Returns (or rethrows) what [process] produced.
Future<R> autoDispose<R>(Procedure<R> process, Disposable disposable) async {
  try {
    return await process();
  } finally {
    await disposable.dispose();
  }
}

/// Scoped-use helper for any [Disposable].
extension DisposalUser on Disposable {
  /// Runs [process] with this object, then disposes it (see [autoDispose]).
  Future<R> use<R>(Usage<Disposable, R> process) =>
      autoDispose(() => process(this), this);
}
