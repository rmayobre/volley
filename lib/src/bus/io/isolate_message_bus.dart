import 'dart:async';
import 'dart:isolate';

import '../../disposable/disposable.dart';
import '../broadcast.dart';
import '../message_bus.dart';

final class IsolateMessageBus implements MessageBus, Disposable {

  final _controller = StreamController<Object>.broadcast(sync: true);
  final SendPort _sendPort;

  late final StreamSubscription? _subscription;

  IsolateMessageBus({
    required ReceivePort receivePort,
    required SendPort sendPort
  }) : _sendPort = sendPort {
    _subscription = receivePort
        .where((message) => message is Broadcast)
        .cast()
        .listen((broadcast) => _controller.add(broadcast.message));
  }

  @override
  Stream<M> messages<M extends Object>() => _controller.stream
      .where((message) => message is M)
      .cast();

  @override
  void publish<M extends Object>(M message) => _sendPort.send(message);

  @override
  Future<void> dispose() => Future.wait([
    if (_subscription != null) _subscription.cancel(),
    _controller.close(),
  ]);
}