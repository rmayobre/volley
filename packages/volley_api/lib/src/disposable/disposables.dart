import 'dart:async';

import 'disposable.dart';

final class Disposables implements Disposable {
  final Iterable<Disposable> _disposables;

  Disposables(this._disposables);

  @override
  Future<void> dispose() async {
    await Future.wait(_disposables.map((d) => d.dispose()).whereType<Future>());
  }
}
