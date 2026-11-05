import 'dart:async';

import '../disposable/disposable.dart';
import 'message_bus.dart';

base class BaseMessageBus implements MessageBus, Disposable {
  final StreamController<Object> _controller;
  StreamSubscription<Object>? _subscription;

  BaseMessageBus({MessageBus? parent})
    : _controller = StreamController.broadcast() {
    if (parent != null) {
      _subscription = parent.messages<Object>().listen((message) {
        _controller.add(message);
      });
    }
  }

  @override
  Stream<M> messages<M extends Object>() =>
      _controller.stream.where((message) => message is M).cast();

  @override
  void publish<M extends Object>(M message) {
    _controller.add(message);
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}
