import 'dart:async';

import 'package:volley_api/volley_api.dart';

import 'singleton_instance.dart' as impl;

/// A stateful reducer with exactly one live instance per subtype, shared
/// across every isolate (native) or the single main thread (web) that calls
/// [Singleton.instance] with the same type.
///
/// Extend one of the two concrete flavours, which differ in what happens when
/// a message arrives while an asynchronous [reduce] is still running:
///
/// * [SerializedSingleton] handles **one message at a time, in the order they
///   were sent**, and replies in that same order. Choose this for state that
///   is read, awaited on and then updated: you don't have to write
///   re-entrancy-safe code.
/// * [ConcurrentSingleton] starts [reduce] for every message as soon as it
///   arrives, so calls may **overlap at their `await`s** and replies may come
///   back in a different order. Choose this for stateless or
///   re-entrancy-safe work, and for any singleton that is called back from
///   inside its own [reduce] (see the deadlock note on [SerializedSingleton]).
///
/// A [reduce] with no `await` in it can never overlap with itself, so for such
/// reducers both flavours behave identically.
///
/// ```dart
/// final class Counter extends SerializedSingleton<CounterState, CounterEvent> {
///   int _count = 0;
///
///   @override
///   CounterState reduce(CounterEvent event) {
///     switch (event) {
///       case Increment(): _count += event.amount;
///       case Decrement(): _count -= event.amount;
///       case Reset(): _count = 0;
///     }
///     return CounterState(_count);
///   }
/// }
/// ```
sealed class Singleton<I extends Message, O extends Message> {
  const Singleton();

  /// Handles one event sent by a caller ([O]) and produces the response ([I])
  /// delivered back to callers. Type parameters follow [Channel]'s convention:
  /// [I] is what callers receive and [O] is what callers send.
  FutureOr<I> reduce(O event);

  /// Returns the shared [Channel] for the [Singleton] subtype [T], building
  /// it via [build] on first access. Subsequent calls with the same [T]
  /// return the cached channel and ignore [build].
  static Future<Channel<I, O>> instance<
    I extends Message,
    O extends Message,
    T extends Singleton<I, O>
  >(T Function() build) => impl.singletonInstance<I, O, T>(build);
}

/// A [Singleton] that handles **one message at a time, in order**.
///
/// While one [reduce] is running (including at its `await`s), later messages
/// wait their turn, and replies are delivered in the order the messages were
/// sent. Messages to *different* singletons never wait for each other.
///
/// ```dart
/// // Safe even though it checks, awaits and then updates:
/// final class Account extends SerializedSingleton<Balance, AccountCmd> {
///   int _balance = 100;
///
///   @override
///   Future<Balance> reduce(AccountCmd cmd) async {
///     if (cmd is Withdraw && _balance >= cmd.amount) {
///       await audit(cmd);
///       _balance -= cmd.amount; // no other message ran in between
///     }
///     return Balance(_balance);
///   }
/// }
/// ```
///
/// **Deadlock warning:** because a message waits for the previous one to
/// finish, a [reduce] that awaits something which sends a message back to the
/// *same* singleton (for example a `coroutine()` that calls
/// `Singleton.instance` for this type) will wait on itself forever. Use a
/// [ConcurrentSingleton] if that call-back pattern is needed.
abstract class SerializedSingleton<I extends Message, O extends Message>
    extends Singleton<I, O> {
  const SerializedSingleton();
}

/// A [Singleton] that starts [reduce] for every message as soon as it arrives.
///
/// Calls may overlap at their `await`s, so [reduce] must be safe to re-enter:
/// don't check a condition, `await`, and then act on the stale check. Replies
/// are sent as each [reduce] completes, which may not be the order the
/// messages were sent.
///
/// ```dart
/// // Each message is independent, so overlapping is fine and faster:
/// final class Resizer extends ConcurrentSingleton<Image, ResizeRequest> {
///   @override
///   Future<Image> reduce(ResizeRequest request) => resize(request);
/// }
/// ```
abstract class ConcurrentSingleton<I extends Message, O extends Message>
    extends Singleton<I, O> {
  const ConcurrentSingleton();
}
