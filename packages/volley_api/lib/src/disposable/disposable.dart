import 'dart:async';

import 'disposables.dart';

typedef Disposer = FutureOr<void> Function();

abstract interface class Disposable {
  factory Disposable(Disposer disposer) = _Disposable;

  static Disposable iterables(Iterable<Disposable> disposables) =>
      Disposables(disposables);

  FutureOr<void> dispose();
}

final class _Disposable implements Disposable {
  final Disposer _disposer;

  _Disposable(this._disposer);

  @override
  FutureOr<void> dispose() => _disposer();
}
