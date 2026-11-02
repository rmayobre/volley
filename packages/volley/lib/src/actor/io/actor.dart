import 'dart:async';
import 'dart:isolate';

import 'package:volley_api/volley_api.dart';

import '../../channel/io/isolate_channel.dart';
import '../../singleton/io/singleton_send_port.dart';
import 'isolate_actor.dart';
import 'isolate_actor_entrypoint.dart';

/// Creates an [Actor] backed by a dedicated [Isolate].
///
/// [reducer] is called inside the isolate for every message of type [I]
/// received on [IsolateActor.channel]. The result of type [O] is emitted on
/// [IsolateActor.responses].
///
/// Every actor also receives a bidirectional [Channel<Object>] connecting it
/// to the main isolate, exposed on the caller side as [IsolateActor.mainChannel].
///
/// [reducer] must be a top-level or static function. Closures that capture
/// mutable state cannot be transferred across the isolate boundary.
///
/// ```dart
/// String echo(String message) => message;
///
/// void main() async {
///   final a = await actor<String, String>(echo);
///   a.responses.listen(print);
///   a.channel.send('hello'); // prints: hello
///   await a.dispose();
/// }
/// ```
Future<Actor<I, O>> actor<I extends Message, O extends Message>(
  FutureOr<O> Function(I) reducer,
) async {
  final handshakePort = ReceivePort();
  final responsePort = ReceivePort();
  final arguments = IsolateEntrypointArgs(
    reducer: reducer,
    sendPort: responsePort.sendPort,
    handshakeSendPort: handshakePort.sendPort,
    singletonSendPort: singletonSendPort,
  );
  final isolate = await Isolate.spawn(entrypoint, arguments);
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
  );
}
