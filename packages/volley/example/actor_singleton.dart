import 'dart:async';

import 'package:volley/volley.dart';

// --- Counter message types ---

sealed class CounterEvent implements Message {}

final class Increment implements CounterEvent {
  const Increment();
}

final class CounterState implements Message {
  final int count;
  const CounterState(this.count);

  @override
  String toString() => 'CounterState(count: $count)';
}

// --- Counter Singleton ---

final class Counter extends SerializedSingleton<CounterState, CounterEvent> {
  int _count = 0;

  @override
  CounterState reduce(CounterEvent event) {
    switch (event) {
      case Increment():
        _count++;
    }
    return CounterState(_count);
  }
}

// --- Actor message types ---
//
// A sealed parent lets the actor use a single type for both request and
// response; actors with distinct types work as well (send I, receive O).

sealed class WorkerMessage implements Message {}

final class WorkerRequest implements WorkerMessage {
  const WorkerRequest();
}

final class WorkerResponse implements WorkerMessage {
  final int count;
  const WorkerResponse(this.count);

  @override
  String toString() => 'WorkerResponse(count: $count)';
}

// --- Actor reducer (must be top-level for isolate transfer) ---
//
// The singletonSendPort is automatically propagated into the new isolate
// via IsolateEntrypointArgs, so Singleton.instance() works here exactly
// as it does on the main isolate — both resolve to the same singleton actor.

Future<WorkerMessage> _workerReducer(WorkerMessage message) async {
  final channel = await Singleton.instance<CounterState, CounterEvent, Counter>(
    Counter.new,
  );

  final next = channel.messages.first;
  channel.send(const Increment());
  final state = await next;

  return WorkerResponse(state.count);
}

// --- Main ---

void main() async {
  await Bootstrapper.initialize();

  // Obtain the singleton channel from the main isolate and increment once.
  final channel = await Singleton.instance<CounterState, CounterEvent, Counter>(
    Counter.new,
  );

  final mainNext = channel.messages.first;
  channel.send(const Increment());
  final mainState = await mainNext;
  print('Main after increment:  $mainState'); // CounterState(count: 1)

  // Spawn a worker actor. Because singletonSendPort is set on the main
  // isolate at this point, it is forwarded into the actor's isolate
  // automatically via IsolateEntrypointArgs.
  final workerActor = await actor<WorkerMessage, WorkerMessage>(_workerReducer);

  // Subscribe before sending so no response is missed.
  final actorResponseFuture =
      workerActor.channel.messages
          .where((m) => m is WorkerResponse)
          .cast<WorkerResponse>()
          .first;

  workerActor.channel.send(const WorkerRequest());

  final workerResponse = await actorResponseFuture;
  print('Actor after increment: $workerResponse'); // WorkerResponse(count: 2)

  // Both the main isolate and the actor incremented the same Counter
  // instance running in the singleton isolate.
  assert(
    workerResponse.count == mainState.count + 1,
    'Singleton state must be shared: expected ${mainState.count + 1}, '
    'got ${workerResponse.count}',
  );

  print('Shared state verified: counter is consistent across isolates.');

  workerActor.dispose();
  await Bootstrapper.shutdown(); // lets the program exit on its own
}
