import 'dart:async';

import 'message_bus.dart';

typedef MessageHandler<M extends Object> = void Function(M message);

extension MessageBusSubscribe on MessageBus {
  StreamSubscription<void> proxyInto<M extends Object>(EventSink<M> sink) =>
      messages<M>().listen((message) => sink.add(message));

  StreamSubscription<void> subscribe<M extends Object>(
    MessageHandler<M> handler,
  ) => messages<M>().listen((message) => handler(message));
}
