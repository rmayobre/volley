import 'dart:async';
import 'dart:collection';

import 'pool.dart';

base class BasePool<T extends Object> implements Pool<T> {

  final _operationsController = StreamController<_PoolOperations<T>>(sync: true);
  final _resources = Queue<T>();
  final _borrowers = Queue<Completer<T>>();
  
  /// Number of instances that were created.
  int _instances = 0;
  
  late final StreamSubscription _subscription;

  final ResourceFactory<T> _create;
  
  @override
  final int size;

  @override
  int get available => _resources.length;

  BasePool(this.size, this._create) : assert(size > 0) {
    _subscription = _operationsController.stream.listen(_performOperation);
  }

  @override
  Future<T> borrow() {
    final completer = Completer<T>();
    _operationsController.add(_Borrowing(completer));
    return completer.future;
  }

  @override
  void release(T resource) => _operationsController.add(_Release(resource));

  @override
  Future<void> dispose() async {
    await Future.wait([
      _subscription.cancel(),
      _operationsController.close()
    ]);
  }

  void _performOperation(_PoolOperations<T> operation) {
    switch(operation) {
      case _Borrowing<T>():
        _borrow(operation.completer);
      case _Release<T>():
        _release(operation.resource);
    }
  }

  void _borrow(Completer<T> completer) {
    if (_resources.isNotEmpty) {
      completer.complete(_resources.removeFirst());
      return;
    }
    if (_instances < size) {
      _instances++;
      completer.complete(_create(_instances));
      return;
    }
    _borrowers.add(completer);
  }

  void _release(T resource) {
    if (_borrowers.isEmpty) {
      _resources.add(resource);
      if (_resources.length > size) throw StateError('Too many resources were released into the pool: ($size)');
      return;
    }
    final completer = _borrowers.removeFirst();
    completer.complete(resource);
  }
}

sealed class _PoolOperations<T extends Object> {}

final class _Borrowing<T extends Object> implements _PoolOperations<T> {

  final Completer<T> completer;

  const _Borrowing(this.completer);
}

final class _Release<T extends Object> implements _PoolOperations<T> {

  final T resource;

  const _Release(this.resource);
}