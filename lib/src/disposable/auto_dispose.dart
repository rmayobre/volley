import 'dart:async';

import 'disposable.dart';

typedef Procedure<R> = FutureOr<R> Function();
typedef Usage<T extends Disposable, R> = FutureOr<R> Function(T disposable);

FutureOr<R> autoDispose<R>(Disposable disposable, Procedure<R> process) async {
  R result;
  try {
    result = await process();
  } finally {
    disposable.dispose();
  }
  return result;
}

extension DisposalUser<T extends Disposable> on T {

  FutureOr<R> use<R>(Usage<T, R> usage) {
    return autoDispose(this, () => usage(this));
  }
}