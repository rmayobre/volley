import 'dart:async';

import '../disposable/disposable.dart';
import 'message_bus.dart';

/// A default in-memory [MessageBus] backed by a broadcast [StreamController].
///
/// Messages are delivered asynchronously to current listeners (broadcast
/// semantics); those published while nobody is listening are dropped. If a
/// [parent] is given, every message published on the parent is also
/// re-published on this bus (but not the other way around). Call [dispose] to
/// detach from the parent and close the bus.
base class BaseMessageBus implements MessageBus, Disposable {
  final StreamController<Object> _controller;
  StreamSubscription<Object>? _subscription;

  /// Creates a bus, optionally forwarding everything published on [parent].
  BaseMessageBus({MessageBus? parent})
    : _controller = StreamController.broadcast() {
    if (parent != null) {
      _subscription = parent.messages<Object>().listen((message) {
        _controller.add(message);
      });
    }
  }

  /// Returns a broadcast stream of published messages that are of type [M].
  @override
  Stream<M> messages<M extends Object>() =>
      _controller.stream.where((message) => message is M).cast();

  /// Delivers [message] to every current listener whose type matches.
  @override
  void publish<M extends Object>(M message) {
    _controller.add(message);
  }

  /// Stops forwarding from the parent (if any) and closes the bus.
  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}
