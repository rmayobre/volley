import 'dart:async';

import 'disposable.dart';

final class Disposables implements Disposable {

  final Iterable<Disposable> _disposables;

  const Disposables(this._disposables);

  @override
  FutureOr<void> dispose() async {
    await Future.wait(
        _disposables
            .map((disposable) => disposable.dispose())
            .whereType<Future>()
    );
  }
}