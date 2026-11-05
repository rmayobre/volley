import 'dart:async';

import '../disposable/disposable.dart';
import 'base_pool.dart';

typedef ResourceFactory<T> = T Function(int index);

/// A fixed-size pool of reusable resources, created lazily by a
/// [ResourceFactory] and lent out one caller at a time.
///
/// Disposing the pool (see [Disposable.dispose]):
///
/// * makes callers that are still waiting for a resource, and any later
///   [execute], fail with a `PoolDisposedException`;
/// * disposes every idle resource that is itself a [Disposable];
/// * lets calls already running finish, and disposes their resource (if it is
///   a [Disposable]) when they hand it back instead of returning it to the
///   pool.
///
/// Disposing more than once is harmless.
abstract interface class Pool<T> implements Disposable {
  factory Pool(int size, ResourceFactory<T> create) => BasePool(size, create);

  int get size;

  int get available;

  FutureOr<R> execute<R>(FutureOr<R> Function(T) compute);
}
