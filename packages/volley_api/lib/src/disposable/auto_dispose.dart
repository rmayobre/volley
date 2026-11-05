import 'dart:async';

import 'disposable.dart';

typedef Procedure<R> = FutureOr<R> Function();
typedef Usage<T, R> = FutureOr<R> Function(Disposable);

Future<R> autoDispose<R>(Procedure<R> process, Disposable disposable) async {
  try {
    return await process();
  } finally {
    await disposable.dispose();
  }
}

extension DisposalUser on Disposable {
  Future<R> use<R>(Usage<Disposable, R> process) =>
      autoDispose(() => process(this), this);
}
