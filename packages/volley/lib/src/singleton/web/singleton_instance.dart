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

  @override
  void send(O message) {
    scheduleMicrotask(() async {
      _controller.add(await _singleton.reduce(message));
    });
  }
}
