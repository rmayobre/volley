import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:volley_api/volley_api.dart';

/// An [Actor] backed by a dedicated [Isolate].
///
/// Obtain an instance via the [actor] function.
@internal
final class IsolateActor<I extends Message, O extends Message>
    implements Actor<I, O> {
  @override
  final Channel<I, O> channel;
  final ReceivePort responsePort;
  final Isolate isolate;

  const IsolateActor({
    required this.channel,
    required this.responsePort,
    required this.isolate,
  });

  @override
  void dispose() {
    responsePort.close();
    isolate.kill(priority: Isolate.immediate);
  }
}
