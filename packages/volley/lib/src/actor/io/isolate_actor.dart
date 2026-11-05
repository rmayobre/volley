import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:volley_api/volley_api.dart';

/// An [Actor] backed by a dedicated [Isolate].
///
/// Obtain an instance via the [actor] function.
///
/// If the isolate dies from an uncaught exception, the actor closes itself and
/// [closed] completes with a [RemoteError] describing the failure.
@internal
final class IsolateActor<I extends Message, O extends Message>
    implements Actor<I, O> {
  @override
  final Channel<I, O> channel;
  final ReceivePort responsePort;
  final Isolate isolate;
  final ReceivePort _errorPort;
  final ReceivePort _exitPort;
  final _closed = Completer<Object?>();
  Object? _error;

  IsolateActor({
    required this.channel,
    required this.responsePort,
    required this.isolate,
    required ReceivePort errorPort,
    required ReceivePort exitPort,
  }) : _errorPort = errorPort,
       _exitPort = exitPort {
    // The isolate reports an uncaught error as [description, stackTrace]
    // immediately before it exits.
    _errorPort.listen((message) {
      if (_error != null) return;
      if (message is List && message.length == 2) {
        _error = RemoteError(message[0].toString(), message[1].toString());
      } else {
        _error = message;
      }
    });
    _exitPort.listen((_) => _close());
  }

  @override
  Future<Object?> get closed => _closed.future;

  void _close() {
    if (_closed.isCompleted) return;
    _errorPort.close();
    _exitPort.close();
    responsePort.close();
    _closed.complete(_error);
  }

  @override
  void dispose() {
    if (_closed.isCompleted) return;
    isolate.kill(priority: Isolate.immediate);
    _close();
  }
}
