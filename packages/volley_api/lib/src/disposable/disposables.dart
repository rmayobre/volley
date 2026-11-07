import 'dart:async';

import 'disposable.dart';

/// A group of [Disposable]s that is disposed together.
///
/// [dispose] runs all members concurrently and completes when every
/// asynchronous disposal has finished. If one fails, the error propagates
/// once the others are done.
final class Disposables implements Disposable {
  final Iterable<Disposable> _disposables;

  Disposables(this._disposables);

  @override
  Future<void> dispose() async {
    await Future.wait(_disposables.map((d) => d.dispose()).whereType<Future>());
  }
}
