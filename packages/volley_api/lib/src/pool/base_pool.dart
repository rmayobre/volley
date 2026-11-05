import 'dart:async';
import 'dart:collection';

import '../disposable/disposable.dart';
import 'pool.dart';
import 'pool_disposed_exception.dart';

final class BasePool<T> implements Pool<T> {
  final Queue<T> _resources;
  final Queue<Completer<T>> _waiters;
  final int _size;
  final ResourceFactory<T> _factory;
  int _created = 0;
  bool _disposed = false;

  BasePool(this._size, this._factory)
    : _resources = Queue(),
      _waiters = Queue();

  @override
  int get available => _resources.length;

  @override
  int get size => _size;

  @override
  Future<R> execute<R>(FutureOr<R> Function(T) compute) async {
    if (_disposed) throw const PoolDisposedException();
    final resource = await _borrow();
    try {
      return await compute(resource);
    } finally {
      _release(resource);
    }
  }

  // Borrowing/releasing mutate _resources/_waiters/_created directly rather
  // than going through an event queue: nothing here ever suspends before
  // those fields are read or written, so — in Dart's single-threaded,
  // cooperative-scheduling model — there's no interleaving to guard against.
  // (An earlier version routed these through a StreamController, which
  // actually made things worse: a stream listener that throws is reported to
  // the current Zone as an uncaught error instead of propagating back to
  // whoever called `.add()`, so a misuse error here would silently bypass
  // `execute()`'s caller entirely rather than rejecting its Future.)
  Future<T> _borrow() {
    if (_resources.isNotEmpty) {
      return Future.value(_resources.removeFirst());
    }
    if (_created < _size) {
      // Only count the resource once it exists: a factory that throws must
      // not use up a slot, or the pool would later wait forever for it.
      final resource = _factory(_created);
      _created++;
      return Future.value(resource);
    }
    final completer = Completer<T>();
    _waiters.add(completer);
    return completer.future;
  }

  void _release(T resource) {
    if (_disposed) {
      // The pool closed while this resource was out: retire it now.
      unawaited(_disposeResource(resource));
      return;
    }
    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete(resource);
    } else if (_resources.length < _size) {
      _resources.add(resource);
    } else {
      throw StateError('Cannot release more resources than the pool size');
    }
  }

  Future<void> _disposeResource(T resource) async {
    if (resource is Disposable) await resource.dispose();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    for (final waiter in _waiters) {
      waiter.completeError(const PoolDisposedException());
    }
    _waiters.clear();

    final idle = _resources.toList();
    _resources.clear();
    await Future.wait(idle.map(_disposeResource));
  }
}
