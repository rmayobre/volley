import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:volley_api/volley_api.dart';

import '../../init/io/bootstrapper.dart';
import '../../singleton/io/singleton_send_port.dart';

/// Entry point of every actor isolate.
///
/// Starts the message loop, bootstraps the isolate (so singletons and
/// coroutines work inside the reducer) and finally sends its input port back
/// through [IsolateEntrypointArgs.handshakeSendPort] to signal it is ready.
@internal
@pragma('vm:entry-point')
void entrypoint(IsolateEntrypointArgs args) async {
  final inputPort = ReceivePort();

  // Start the message loop before bootstrapping so the singleton actor can
  // process its own SingletonInit<CoroutineExecutor> during self-init.
  //
  // listen() (not asyncMap) is intentional: asyncMap pauses the subscription
  // while its future is pending, which would deadlock nested coroutine calls
  // that queue a new message while an outer job is still executing. Ordering
  // for ordinary actors is therefore done with an explicit queue instead.
  Future<void> handle(dynamic message) async {
    final response = await args.reduce(message);
    if (response == null) return;
    try {
      args.sendPort.send(response);
    } on ArgumentError catch (e) {
      throw UnsendableMessageException(response.runtimeType, e);
    }
  }

  var queue = Future<void>.value();
  inputPort.listen((message) {
    if (args.serialized) {
      // One message at a time, in order. An uncaught error ends the queue and
      // the isolate, exactly as it would without queuing.
      queue = queue.then((_) => handle(message));
    } else {
      handle(message);
    }
  });

  // When singletonSendPort is null this is the root singleton actor; point it
  // at its own inputPort so Singleton.instance / coroutine() work inside jobs.
  singletonSendPort = args.singletonSendPort ?? inputPort.sendPort;
  await Bootstrapper.initialize();

  args.handshakeSendPort.send(inputPort.sendPort);
}

/// Everything an actor isolate needs, bundled into one sendable object.
@internal
final class IsolateEntrypointArgs<I extends Object, O extends Object> {
  /// Handles each incoming [O] and produces the [I] that is sent back.
  final FutureOr<I> Function(O) reducer;

  /// Where responses are sent (the caller's end of the channel).
  final SendPort sendPort;

  /// Receives the isolate's input port once it has finished starting up.
  final SendPort handshakeSendPort;

  /// The shared singleton host, or `null` if this isolate *is* that host.
  final SendPort? singletonSendPort;

  /// Whether messages are handled one at a time, in order. Only the shared
  /// singleton host turns this off: it must start work for every message
  /// immediately so that concurrent singletons (and nested coroutines, which
  /// call back into the coroutine executor) don't wait on each other.
  final bool serialized;

  const IsolateEntrypointArgs({
    required this.reducer,
    required this.sendPort,
    required this.handshakeSendPort,
    this.singletonSendPort,
    this.serialized = true,
  });

  /// Runs [reducer] on [message], or returns `null` (no response) if the
  /// message is not an [O].
  FutureOr<Object>? reduce(dynamic message) {
    if (message is! O) return null;
    return reducer(message);
  }
}
