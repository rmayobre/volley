import 'dart:async';

import 'base_pool.dart';

typedef ResourceFactory<T> = T Function(int index);

abstract interface class Pool<T> {
  factory Pool(int size, ResourceFactory<T> create) => BasePool(size, create);

  int get size;

  int get available;

  FutureOr<R> execute<R>(FutureOr<R> Function(T) compute);
}
