import 'dart:async';

import 'message_bus.dart';

/// A callback invoked with each message of type [M].
typedef MessageHandler<M extends Object> = void Function(M message);

/// Convenience subscription helpers for [MessageBus].
extension MessageBusSubscribe on MessageBus {
  /// Forwards every message of type [M] into [sink].
  ///
  /// The sink is not closed when the returned subscription is cancelled.
  StreamSubscription<void> proxyInto<M extends Object>(EventSink<M> sink) =>
      messages<M>().listen((message) => sink.add(message));

  /// Calls [handler] for every message of type [M] until the returned
  /// subscription is cancelled.
  StreamSubscription<void> subscribe<M extends Object>(
    MessageHandler<M> handler,
  ) => messages<M>().listen((message) => handler(message));
}
