import 'dart:async';

import 'package:volley_api/volley_api.dart';

import '../singleton.dart';

/// Shallow web implementation of [Singleton.instance].
///
/// There are no isolates on the web, so there is nothing to route across:
/// the [Singleton] instance is built once and kept in-process, and [reduce]
/// runs directly on the caller's thread.
final _instances = <Type, Singleton<dynamic, dynamic>>{};
final _channels = <Type, Channel<dynamic, dynamic>>{};

/// Disposes every [Disposable] singleton and forgets all instances, so the
/// next `Singleton.instance` builds them from scratch.
Future<void> disposeSingletons() async {
  final instances = _instances.values.toList();
  _instances.clear();
  _channels.clear();
  for (final instance in instances) {
    if (instance case final Disposable d) await d.dispose();
  }
}

Future<Channel<I, O>> singletonInstance<
  I extends Message,
  O extends Message,
  T extends Singleton<I, O>
>(T Function() build) async {
  final cached = _channels[T];
  if (cached != null) return cached as Channel<I, O>;

  final instance = _instances.putIfAbsent(T, build) as T;
  final channel = _WebSingletonChannel<I, O>(instance);
  _channels[T] = channel;
  return channel;
}

final class _WebSingletonChannel<I extends Message, O extends Message>
    implements Channel<I, O> {
  final Singleton<I, O> _singleton;
  final _controller = StreamController<I>.broadcast();

  _WebSingletonChannel(this._singleton);

  @override
  Stream<I> get messages => _controller.stream;

  /// The tail of the queue of pending messages (serialized singletons only).
  Future<void> _queue = Future<void>.value();

  Future<void> _handle(O message) async {
    try {
      _controller.add(await _singleton.reduce(message));
    } catch (e, st) {
      _controller.addError(e, st);
    }
  }

  @override
  void send(O message) {
    if (_singleton is SerializedSingleton) {
      _queue = _queue.then((_) => _handle(message));
    } else {
      scheduleMicrotask(() => _handle(message));
    }
  }
}
