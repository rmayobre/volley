import 'dart:async';

import 'package:meta/meta.dart';

import '../disposable/disposable.dart';
import 'message_bus.dart';

base class BaseMessageBus implements MessageBus, Disposable {

  @protected
  final controller = StreamController<Object>.broadcast();

  late final StreamSubscription? _subscription;

  BaseMessageBus([MessageBus? parent]) {
    _subscription = parent?.messages()
        .listen((message) => controller.add(message));
  }

  @override
  Stream<M> messages<M extends Object>() => controller.stream
      .where((message) => message is M)
      .cast();

  @override
  void publish<M extends Object>(M message) => controller.add(message);

  @override
  Future<void> dispose() => Future.wait([
    if (_subscription != null) _subscription.cancel(),
    controller.close(),
  ]);
}