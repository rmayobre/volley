import 'dart:async';

import 'package:volley_api/volley_api.dart';

typedef Computation<R> = FutureOr<R> Function();

sealed class CoroutineMessage implements Message {
  const CoroutineMessage();
}

final class CoroutineTask<R> extends CoroutineMessage with DistinctMessage {
  final Computation<R> compute;
  CoroutineTask(this.compute);
}

final class CoroutineDisposal extends CoroutineMessage
    implements DistinctMessage {
  @override
  final String id;
  const CoroutineDisposal(this.id);
}
