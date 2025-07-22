import 'dart:async';

import '../disposable/disposable.dart';
import 'base_pool.dart';

typedef ResourceAllocation<T extends Object, R> = FutureOr<R> Function(T resource);
typedef ResourceFactory<R extends Object> = FutureOr<R> Function(int index);

abstract interface class Pool<T extends Object> implements Disposable {

  factory Pool({int size = 1, required ResourceFactory<T> create}) {
    return BasePool(size, create);
  }

  /// The size of the resource pool.
  int get size;

  /// Current number of available resource(s) in the pool.
  int get available;

  /// Attempt to borrow some resource from the pool. Must
  /// wait for the next available or newly constructed resource.
  Future<T> borrow();

  /// Releases the [resource] and makes it available for the
  /// next borrower from the pool.
  void release(T resource);
}

/// Safely use the [Pool]'s allocated resource. Support asynchronous operations.
/// In the event of an error throw, this function will always make sure to release
/// the borrowed resource.
Future<R> withResource<T extends Object, R>(Pool<T> pool, ResourceAllocation<T, R> allocate) async {
  final resource = await pool.borrow();
  final R result;
  try {
    result = await allocate(resource);
  } finally {
    pool.release(resource);
  }
  return result;
}