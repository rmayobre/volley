import 'dart:async';

import 'package:volley_api/volley_api.dart';

import 'web_actor.dart';

/// Creates an [Actor] that runs the [reducer] on the current (main) thread.
///
/// On web platforms, [dart:isolate] is unavailable, so messages are processed
/// on the main thread instead of a dedicated isolate.
///
/// [reducer] is called directly for every message of type [O] sent on
/// [WebActor.channel], one at a time and in order. The result of type [I] is
/// received on the same channel's `messages` stream. If [reducer] throws, the
/// actor closes and [Actor.closed] completes with the error.
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
  return WebActor<I, O>(reducer);
}
