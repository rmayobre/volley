import 'dart:async';

import '../disposable/disposable.dart';
import 'base_pool.dart';

/// Creates the resource at [index] (0-based, in creation order).
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
  /// Creates a pool holding at most [size] resources built by [create].
  factory Pool(int size, ResourceFactory<T> create) => BasePool(size, create);

  /// The maximum number of resources the pool will create.
  int get size;

  /// The number of idle resources currently ready to be borrowed.
  int get available;

  /// Borrows a resource, runs [compute] with it and returns the resource to
  /// the pool afterwards (even if [compute] throws).
  ///
  /// Waits for a free resource when all [size] are in use. Throws
  /// `PoolDisposedException` if the pool is disposed.
  FutureOr<R> execute<R>(FutureOr<R> Function(T) compute);
}
