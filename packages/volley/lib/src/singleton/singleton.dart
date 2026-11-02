import 'dart:async';

import 'package:volley_api/volley_api.dart';

import 'singleton_instance.dart' as impl;

/// A stateful actor with exactly one live instance per [Singleton] subtype,
/// shared across every isolate (native) or the single main thread (web) that
/// calls [Singleton.instance] with the same type.
///
/// ```dart
/// final class Counter extends Singleton<CounterEvent, CounterState> {
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
abstract class Singleton<I extends Message, O extends Message> {
  FutureOr<O> reduce(I event);

  /// Returns the shared [Channel] for the [Singleton] subtype [T], building
  /// it via [build] on first access. Subsequent calls with the same [T]
  /// return the cached channel and ignore [build].
  static Future<Channel<O, I>> instance<
    I extends Message,
    O extends Message,
    T extends Singleton<I, O>
  >(T Function() build) => impl.singletonInstance<I, O, T>(build);
}
