import 'dart:async';

import 'message_bus.dart';

typedef MessageHandler<M extends Object> = void Function(M message);

extension MesssageBusExtensions on MessageBus {

  StreamSubscription proxyInto(EventSink<Object> sink) => messages()
      .listen((message) => sink.add(message));

  StreamSubscription<M> subscribe<M extends Object>(MessageHandler<M> handler) => messages<M>()
      .listen(handler);
}