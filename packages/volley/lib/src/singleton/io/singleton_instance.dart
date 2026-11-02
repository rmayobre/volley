import 'dart:async';
import 'dart:isolate';

import 'package:volley_api/volley_api.dart';

import '../singleton.dart';
import 'singleton_operation.dart';
import 'singleton_results.dart';
import 'singleton_send_port.dart';

final _channels = <Type, Channel<dynamic, dynamic>>{};

Future<Channel<O, I>> singletonInstance<
  I extends Message,
  O extends Message,
  T extends Singleton<I, O>
>(T Function() build) async {
  final cached = _channels[T];
  if (cached != null) return cached as Channel<O, I>;

  final replyPort = ReceivePort();
  singletonSendPort?.send(
    SingletonInit<T>(T, build, replyTo: replyPort.sendPort),
  );
  await replyPort.first;
  replyPort.close();
  final channel = _SingletonChannel<T, I, O>();
  _channels[T] = channel;
  return channel;
}

final class _SingletonChannel<
  T extends Singleton<I, O>,
  I extends Message,
  O extends Message
>
    implements Channel<O, I> {
  final _replyPort = ReceivePort();
  final _controller = StreamController<O>.broadcast();

  _SingletonChannel() {
    _replyPort.listen((msg) {
      if (msg is SingletonResponse) _controller.add(msg.response as O);
    });
  }

  @override
  Stream<O> get messages => _controller.stream;

  @override
  void send(I message) {
    singletonSendPort?.send(
      SingletonMessage<I>(T, message, replyTo: _replyPort.sendPort),
    );
  }
}
