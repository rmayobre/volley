import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:volley_api/volley_api.dart';

import '../../actor/io/actor.dart' show spawnActor;
import '../singleton.dart';
import 'singleton_operation.dart';
import 'singleton_results.dart';

final _singletons = <Type, Singleton<dynamic, dynamic>>{};

/// The tail of each [SerializedSingleton]'s queue of pending messages.
final _queues = <Type, Future<void>>{};

/// Runs [task] after every earlier task for [type] has finished.
///
/// [task] must not throw (the host catches reduce errors itself), so the
/// queue can never get stuck on a failure.
Future<T> _enqueue<T>(Type type, Future<T> Function() task) {
  final previous = _queues[type] ?? Future<void>.value();
  final result = previous.then((_) => task());
  _queues[type] = result.then<void>((_) {}, onError: (_) {});
  return result;
}

Future<SingletonResult> _reduce(
  Singleton<dynamic, dynamic> singleton,
  Object? message,
) async {
  try {
    return SingletonResponse((await singleton.reduce(message)) as Message);
  } catch (e, st) {
    return SingletonFailure(e, st.toString());
  }
}

/// Runs inside the shared singleton actor's isolate.
///
/// Nothing a [Singleton] does may escape this reducer: an uncaught error
/// would kill the isolate and with it every singleton and coroutine. Build
/// and reduce failures are therefore caught and reported to the caller as a
/// [SingletonFailure].
@internal
Future<Actor<SingletonResult, SingletonOperation>> spawnSingletonActor() {
  return spawnActor<SingletonResult, SingletonOperation>((message) async {
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
      case SingletonShutdown():
        SingletonResult result = SingletonStopped();
        try {
          for (final singleton in _singletons.values) {
            if (singleton case final Disposable d) await d.dispose();
          }
        } catch (e, st) {
          // Still confirm, so shutdown never waits forever on a bad dispose.
          result = SingletonFailure(e, st.toString());
        }
        _singletons.clear();
        _queues.clear();
        return _reply(message.replyTo, result);
      case SingletonMessage():
        final singleton = _singletons[message.singletonType];
        final SingletonResult result;
        if (singleton == null) {
          result = SingletonFailure(
            StateError('Singleton ${message.singletonType} is not registered'),
            StackTrace.current.toString(),
          );
        } else if (singleton is SerializedSingleton) {
          result = await _enqueue(
            message.singletonType,
            () => _reduce(singleton, message.message),
          );
        } else {
          result = await _reduce(singleton, message.message);
        }
        return _reply(message.replyTo, result);
    }
  }, serialized: false);
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
