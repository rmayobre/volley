import 'dart:async';

import 'actor.dart';
import 'io/isolate_mailbox.dart';
import 'mailbox.dart';

typedef ActorFactory<I extends Object, O extends Object> = Actor<I, O> Function();
typedef Reducer<I extends Object, O extends Object> = FutureOr<O> Function(I message);

Future<Mailbox<I, O>> spawn<I extends Object, O extends Object>(Reducer<I, O> reducer) {
  return IsolateMailbox.spawn(() => _ReactiveActor(reducer));
}

Future<Mailbox<I, O>> spawnActor<I extends Object, O extends Object>(ActorFactory<I, O> factory) {
  return IsolateMailbox.spawn(factory);
}

final class _ReactiveActor<I extends Object, O extends Object> implements Actor<I, O> {

  final Reducer<I, O> reduce;

  _ReactiveActor(this.reduce);

  @override
  FutureOr<O> handleMessage(I message) => reduce(message);

}