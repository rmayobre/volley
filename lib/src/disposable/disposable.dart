import 'dart:async';

import 'disposables.dart';

typedef Disposer = FutureOr<void> Function();

abstract interface class Disposable {

  factory Disposable(Disposer dispose) => _Disposable(dispose);

  static Disposable iterables(Iterable<Disposable> disposables) => Disposables(disposables);

  FutureOr<void> dispose();
}

final class _Disposable implements Disposable {

  final Disposer _dispose;

  const _Disposable(this._dispose);

  @override
  FutureOr<void> dispose() => _dispose;
}