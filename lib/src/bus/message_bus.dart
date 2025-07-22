import 'dart:async';

abstract interface class MessageBus {

  void publish<M extends Object>(M message);

  Stream<M> messages<M extends Object>();
}