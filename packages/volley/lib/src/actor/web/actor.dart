import 'dart:async';

import 'package:volley_api/volley_api.dart';

import '../../channel/web/web_stream_channel.dart';
import 'web_actor.dart';

/// Creates an [Actor] that runs the [reducer] on the current (main) thread.
///
/// On web platforms, [dart:isolate] is unavailable, so messages are processed
/// on the main thread instead of a dedicated isolate.
///
/// [reducer] is called directly for every message of type [I] sent on
/// [WebActor.channel]. The result of type [O] is emitted on
/// [WebActor.responses].
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
  final channel = WebStreamChannel<I, O>();
  return WebActor<I, O>(channel);
}
