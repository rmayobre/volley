import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';

import 'package:volley_api/volley_api.dart';

import '../../channel/io/isolate_channel.dart';
import '../../singleton/io/singleton_send_port.dart';
import 'isolate_actor.dart';
import 'isolate_actor_entrypoint.dart';

/// Creates an [Actor] backed by a dedicated [Isolate].
///
/// [reducer] is called inside the isolate for every message of type [O] sent
/// on [IsolateActor.channel]. The result of type [I] is received on the same
/// channel's `messages` stream.
///
/// If [reducer] (or anything else in the actor's isolate) throws an uncaught
/// exception, the actor closes itself and [Actor.closed] completes with the
/// error. [Actor.closed] also completes (with `null`) after `dispose()`.
///
/// [reducer] must be a top-level or static function. Closures that capture
/// mutable state cannot be transferred across the isolate boundary.
///
/// ```dart
/// void main() async {
///   final a = await actor<Response, Request>(handle);
///   a.channel.messages.listen(print); // receives Response (I)
///   a.channel.send(Request()); // sends Request (O)
///   a.dispose();
/// }
/// ```
Future<Actor<I, O>> actor<I extends Message, O extends Message>(
  FutureOr<I> Function(O) reducer,
) => spawnActor<I, O>(reducer);

const Object _isolateDied = Object();

/// Implementation of [actor]. [entry] replaces the isolate's entrypoint and
/// exists so tests can simulate an isolate that fails while starting up.
@visibleForTesting
@internal
Future<Actor<I, O>> spawnActor<I extends Message, O extends Message>(
  FutureOr<I> Function(O) reducer, {
  void Function(IsolateEntrypointArgs<I, O>) entry = entrypoint,
}) async {
  final handshakePort = ReceivePort();
  final responsePort = ReceivePort();
  final arguments = IsolateEntrypointArgs(
    reducer: reducer,
    sendPort: responsePort.sendPort,
    handshakeSendPort: handshakePort.sendPort,
    singletonSendPort: singletonSendPort,
  );
  final errorPort = ReceivePort();
  final exitPort = ReceivePort();
  final isolate = await Isolate.spawn(
    entry,
    arguments,
    onError: errorPort.sendPort,
    onExit: exitPort.sendPort,
  );
  final errors = errorPort.asBroadcastStream();
  final exits = exitPort.asBroadcastStream();

  // The isolate may die before it ever completes the handshake (e.g. it
  // fails while bootstrapping); waiting on the handshake alone would hang.
  Object? startupError;
  final errorWatch = errors.listen((m) => startupError ??= isolateError(m));
  final Object handshake = await Future.any<Object>([
    handshakePort.first.then((message) => message as Object),
    exits.first.then((_) => _isolateDied),
  ]);
  await errorWatch.cancel();
  handshakePort.close();
  if (handshake is! SendPort) {
    responsePort.close();
    errorPort.close();
    exitPort.close();
    throw startupError ??
        StateError('The actor isolate exited before it finished starting.');
  }
  final actorSendPort = handshake;
  final channel = IsolateChannel<I, O>(
    receivePort: responsePort,
    sendPort: actorSendPort,
  );
  return IsolateActor<I, O>(
    channel: channel,
    responsePort: responsePort,
    isolate: isolate,
    errorPort: errorPort,
    exitPort: exitPort,
    errors: errors,
    exits: exits,
  );
}
