import 'dart:async';

import 'package:volley_api/volley_api.dart';

/// Work handed to `coroutine()`; may be synchronous or asynchronous.
typedef Computation<R> = FutureOr<R> Function();

/// A request sent to the coroutine executor.
sealed class CoroutineMessage implements Message {
  const CoroutineMessage();
}

/// Asks the executor to run [compute]; its [id] identifies the job.
final class CoroutineTask<R> extends CoroutineMessage with DistinctMessage {
  final Computation<R> compute;
  CoroutineTask(this.compute);
}

/// Asks the executor to cancel the job with the given [id].
final class CoroutineDisposal extends CoroutineMessage
    implements DistinctMessage {
  @override
  final String id;
  const CoroutineDisposal(this.id);
}
