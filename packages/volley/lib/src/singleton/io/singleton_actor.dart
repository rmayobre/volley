import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:volley_api/volley_api.dart';

import '../../actor/actor.dart';
import '../singleton.dart';
import 'singleton_operation.dart';
import 'singleton_results.dart';

final _singletons = <Type, Singleton<dynamic, dynamic>>{};

/// Runs inside the shared singleton actor's isolate.
///
/// Nothing a [Singleton] does may escape this reducer: an uncaught error
/// would kill the isolate and with it every singleton and coroutine. Build
/// and reduce failures are therefore caught and reported to the caller as a
/// [SingletonFailure].
@internal
Future<Actor<SingletonResult, SingletonOperation>> spawnSingletonActor() {
  return actor<SingletonResult, SingletonOperation>((message) async {
    switch (message) {
      case SingletonInit<Singleton<Message, Message>>():
        SingletonResult result;
        try {
          _singletons.putIfAbsent(message.singletonType, message.build);
          result = SingletonConstructed();
        } catch (e, st) {
          result = SingletonFailure(e, st.toString());
        }
        return _reply(message.replyTo, result);
      case SingletonMessage():
        SingletonResult result;
        final singleton = _singletons[message.singletonType];
        if (singleton == null) {
          result = SingletonFailure(
            StateError('Singleton ${message.singletonType} is not registered'),
            StackTrace.current.toString(),
          );
        } else {
          try {
            result = SingletonResponse(
              (await singleton.reduce(message.message)) as Message,
            );
          } catch (e, st) {
            result = SingletonFailure(e, st.toString());
          }
        }
        return _reply(message.replyTo, result);
    }
  });
}

/// Sends [result] to [replyTo] and returns what was actually sent.
///
/// If [result] can't cross the isolate boundary, a [SingletonFailure]
/// describing that is sent instead.
SingletonResult _reply(SendPort? replyTo, SingletonResult result) {
  if (replyTo == null) return result;
  try {
    replyTo.send(result);
    return result;
  } on ArgumentError catch (e) {
    final SingletonResult fallback = switch (result) {
      SingletonFailure() => result.asRemoteError(),
      SingletonResponse(:final response) => SingletonFailure(
        UnsendableMessageException(response.runtimeType, e),
        StackTrace.current.toString(),
      ),
      _ => SingletonFailure(e, StackTrace.current.toString()),
    };
    try {
      replyTo.send(fallback);
    } on ArgumentError {
      replyTo.send(
        fallback is SingletonFailure ? fallback.asRemoteError() : fallback,
      );
    }
    return fallback;
  }
}
