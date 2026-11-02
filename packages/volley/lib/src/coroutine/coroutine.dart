import 'dart:async';

import 'package:volley_api/volley_api.dart';

import '../init/bootstrapper.dart';
import 'coroutine_impl.dart';
import 'coroutine_message.dart';
import 'coroutine_result.dart';

export 'coroutine_message.dart' show Computation;

Coroutine<R> coroutine<R>(Computation<R> compute) {
  final channel = Bootstrapper.coroutineChannel;
  final job = CoroutineTask(compute);
  final impl = CoroutineImpl<R>(channel, job.id);

  StreamSubscription<CoroutineResult>? subscription;
  subscription = channel.messages.listen((message) {
    if (message.id != job.id) return;
    subscription?.cancel();
    if (!message.isCancelled) impl.complete(message.value as R);
  });

  // Cancel the subscription once the result settles (normal completion or
  // CoroutineDisposedException), so we don't leave a dangling listener.
  // `whenComplete` returns a new future that re-emits the error, so mark it
  // as handled; callers observe the error through `impl.result` itself.
  impl.result.whenComplete(() => subscription?.cancel()).ignore();

  channel.send(job);
  return impl;
}
