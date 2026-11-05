import 'dart:async';
import 'dart:isolate';

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
) async {
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
    entrypoint,
    arguments,
    onError: errorPort.sendPort,
    onExit: exitPort.sendPort,
  );
  final actorSendPort = await handshakePort.first as SendPort;
  handshakePort.close();
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
  );
}
