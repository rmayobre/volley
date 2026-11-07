import 'dart:async';

import 'disposables.dart';

/// A callback that releases a resource.
typedef Disposer = FutureOr<void> Function();

/// Something that holds resources and can release them.
///
/// Implementations should make [dispose] safe to call more than once.
abstract interface class Disposable {
  /// Wraps [disposer] as a [Disposable] that runs it on [dispose].
  const factory Disposable(Disposer disposer) = _Disposable;

  /// Combines [disposables] into one that disposes all of them concurrently.
  static Disposable iterables(Iterable<Disposable> disposables) =>
      Disposables(disposables);

  /// Releases the held resources. May complete asynchronously.
  FutureOr<void> dispose();
}

final class _Disposable implements Disposable {
  final Disposer _disposer;

  const _Disposable(this._disposer);

  @override
  FutureOr<void> dispose() => _disposer();
}
