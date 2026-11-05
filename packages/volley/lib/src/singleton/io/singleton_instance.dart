import 'dart:async';
import 'dart:isolate';

import 'package:volley_api/volley_api.dart';

import '../singleton.dart';
import 'singleton_operation.dart';
import 'singleton_results.dart';
import 'singleton_send_port.dart';

final _channels = <Type, Channel<dynamic, dynamic>>{};

/// Closes every cached singleton channel in this isolate, so their reply ports
/// stop keeping the isolate alive, and forgets them.
void closeSingletonChannels() {
  for (final channel in _channels.values) {
    (channel as _SingletonChannel).close();
  }
  _channels.clear();
}

Future<Channel<I, O>> singletonInstance<
  I extends Message,
  O extends Message,
  T extends Singleton<I, O>
>(T Function() build) async {
  final cached = _channels[T];
  if (cached != null) return cached as Channel<I, O>;

  final replyPort = ReceivePort();
  singletonSendPort?.send(
    SingletonInit<T>(T, build, replyTo: replyPort.sendPort),
  );
  final reply = await replyPort.first;
  replyPort.close();
  if (reply is SingletonFailure) {
    // Don't cache anything: a later call may retry building.
    Error.throwWithStackTrace(
      reply.error,
      StackTrace.fromString(reply.stackTrace),
    );
  }
  final channel = _SingletonChannel<T, I, O>();
  _channels[T] = channel;
  return channel;
}

final class _SingletonChannel<
  T extends Singleton<I, O>,
  I extends Message,
  O extends Message
>
    implements Channel<I, O> {
  final _replyPort = ReceivePort();
  final _controller = StreamController<I>.broadcast();

  _SingletonChannel() {
    _replyPort.listen((msg) {
      switch (msg) {
        case SingletonResponse():
          _controller.add(msg.response as I);
        case SingletonFailure():
          _controller.addError(
            msg.error,
            StackTrace.fromString(msg.stackTrace),
          );
      }
    });
  }

  void close() {
    _replyPort.close();
    _controller.close();
  }

  @override
  Stream<I> get messages => _controller.stream;

  @override
  void send(O message) {
    singletonSendPort?.send(
      SingletonMessage<O>(T, message, replyTo: _replyPort.sendPort),
    );
  }
}
