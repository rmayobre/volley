import 'dart:async';
import 'dart:io';

import 'package:volley/volley.dart';

// --- Messages ---

sealed class CounterEvent implements Message {}

final class Increment implements CounterEvent {
  final int amount;
  const Increment([this.amount = 1]);
}

final class Decrement implements CounterEvent {
  final int amount;
  const Decrement([this.amount = 1]);
}

final class Reset implements CounterEvent {
  const Reset();
}

final class CounterState implements Message {
  final int count;
  const CounterState(this.count);

  @override
  String toString() => 'CounterState(count: $count)';
}

// --- Singleton ---

final class Counter extends SerializedSingleton<CounterState, CounterEvent> {
  int _count = 0;

  @override
  CounterState reduce(CounterEvent event) {
    switch (event) {
      case Increment():
        _count += event.amount;
      case Decrement():
        _count -= event.amount;
      case Reset():
        _count = 0;
    }
    return CounterState(_count);
  }
}

// --- Usage ---

void main() async {
  await Bootstrapper.initialize();

  final channel = await Singleton.instance<CounterState, CounterEvent, Counter>(
    Counter.new,
  );

  final completer = Completer<void>();
  int received = 0;

  channel.messages.listen((state) {
    print(state);
    if (++received == 5) completer.complete();
  });

  channel.send(const Increment()); // CounterState(count: 1)
  channel.send(const Increment(5)); // CounterState(count: 6)
  channel.send(const Decrement(2)); // CounterState(count: 4)
  channel.send(const Reset()); // CounterState(count: 0)

  // Calling instance() again returns the cached channel; factory is ignored.
  final same = await Singleton.instance<CounterState, CounterEvent, Counter>(
    Counter.new,
  );

  same.send(const Increment(10)); // CounterState(count: 10)

  await completer.future;
  exit(0);
}
