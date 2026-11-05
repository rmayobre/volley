# volley

Standard implementation of the volley concurrency framework: `actor()`,
`coroutine()`, and `Singleton`, backed by real `dart:isolate`s on native
platforms and an in-process stub anywhere isolates aren't available (see
[`web`](../volley_workers), which swaps the stub for real Web Workers).

Re-exports everything from [`volley_api`](../volley_api), so importing
`package:volley/volley.dart` is enough for both the interfaces and the
implementation.

## Setup and shutdown

Call `Bootstrapper.initialize()` once, before using `coroutine()` or
`Singleton.instance()` (`actor()` calls it for you). It is safe to call more
than once.

```dart
import 'package:volley/volley.dart';

void main() async {
  await Bootstrapper.initialize();
  // ... actor()/coroutine()/Singleton.instance() are safe to use from here.

  await Bootstrapper.shutdown(); // lets the program exit on its own
}
```

On native platforms the shared singleton host runs in its own isolate, which
keeps the process alive after `main` returns. `Bootstrapper.shutdown()` stops
it: it fails unfinished coroutines with a `CoroutineDisposedException`, calls
`dispose()` on every singleton that implements `Disposable`, and stops the
host. Dispose your actors yourself first. After `shutdown()` you may call
`initialize()` again; singletons then start from scratch. Only the isolate that
called `initialize()` first (normally the main one) can shut down.

## The three primitives

### `actor<I, O>(reducer)`

A dedicated isolate running one `FutureOr<I> Function(O)` reducer for its
whole lifetime, talking back over `Actor.channel`. Type parameters follow
`Channel`'s convention from the caller's side: `I` is what you *receive*
(the reducer's output) and `O` is what you *send* (the reducer's input).
Messages are handled one at a time, in order, on both VM and web, so
responses arrive in the order the messages were sent even for asynchronous
reducers. If the reducer throws, the actor closes itself and `Actor.closed` completes
with the error (`null` after a normal `dispose()`).

```dart
String echo(String message) => message;

void main() async {
  await Bootstrapper.initialize();
  final a = await actor<String, String>(echo);
  a.channel.messages.listen(print);
  a.channel.send('hello'); // prints: hello
  await a.dispose();
}
```

**`reducer` must be a top-level or static function** — a closure capturing
mutable state can't be transferred across the isolate boundary.

### `coroutine<R>(compute)`

A single, one-shot computation dispatched to a shared coroutine executor
isolate (spawned once, reused for every call) rather than a fresh isolate
per job:

```dart
final sum = await coroutine(() => _sumRange(0, 500000)).result;
```

If the computation throws, `result` completes with that error (its type and
stack trace are preserved when the error can cross isolates; otherwise a
`RemoteError` describing it).

Fire several off concurrently with `Future.wait` before awaiting any one of
them — see
[`example/concurrent_coroutines.dart`](example/concurrent_coroutines.dart).

### `SerializedSingleton<I, O>` / `ConcurrentSingleton<I, O>`

A stateful reducer (`FutureOr<I> reduce(O event)`: `I` is what callers
receive, `O` is what they send) with exactly one live instance per subtype, shared across
every isolate (native) or the single main thread (web) that resolves it:

```dart
sealed class CounterEvent implements Message {}
final class Increment implements CounterEvent { const Increment(); }
final class CounterState implements Message {
  final int count;
  const CounterState(this.count);
}

final class Counter extends SerializedSingleton<CounterState, CounterEvent> {
  int _count = 0;

  @override
  CounterState reduce(CounterEvent event) {
    switch (event) {
      case Increment(): _count++;
    }
    return CounterState(_count);
  }
}

final channel = await Singleton.instance<CounterState, CounterEvent, Counter>(Counter.new);
channel.send(const Increment());
```

If a singleton's `reduce` throws, the singleton (and everything else) keeps
running and the error is delivered as an **error event on the channel's
`messages` stream**, with its original stack trace. As with any stream error,
it is uncaught (and ends a Dart program) unless a listener handles it, so pass
an `onError`:

```dart
channel.messages.listen(print, onError: (Object e, StackTrace s) => log(e));
```

Replies aren't tied to the message that caused them: every listener on a
channel sees every reply and error for that singleton. If it fails to build, `Singleton.instance` throws.

Pick the flavour that matches how `reduce` uses `await`:

| | `SerializedSingleton` | `ConcurrentSingleton` |
|---|---|---|
| Messages | one at a time, in send order | each starts immediately and may overlap |
| Replies | in send order | in completion order |
| `reduce` must be re-entrancy safe | no | yes (don't check, `await`, then act on the stale check) |
| Called back from inside its own `reduce` | **deadlocks** | fine |
| Use for | stateful logic that awaits | stateless or re-entrancy-safe work |

A `reduce` with no `await` can't overlap with itself, so both behave the
same for it. Different singletons never wait for each other. (`Singleton`
itself is sealed: extend one of the two flavours.)

Every subsequent call to `Singleton.instance<...>()` with the same type
returns the *same* cached channel and ignores the `build` factory — the
class only reads it on first access. Calling `Singleton.instance` from
inside another `actor()`'s isolate resolves to the same shared instance as
the main isolate, since `Bootstrapper` forwards the singleton actor's
`SendPort` into every isolate it spawns.

See [`example/actor_singleton.dart`](example/actor_singleton.dart) for a
worked end-to-end example proving state is shared between the main isolate
and a worker actor.

## The stub/io/web conditional-export pattern

`actor()` and `Bootstrapper` are each three files behind one switchboard —
`stub/` (throws `UnimplementedError`), `io/` (real isolates), `web/` (an
in-process shim; real Web Workers come from
[`volley_workers`](../volley_workers) instead) — selected at compile time.
See the root `CLAUDE.md` for the exact shape and where to add a new one.

## Best practices

- **Call `Bootstrapper.initialize()` exactly once, before anything else.**
  Every primitive here depends on it having run; skipping it, or calling it
  from inside a spawned isolate's own `main()`, isn't necessary — the
  isolate entrypoint already calls it for you.
- **Keep `actor()` reducers top-level or static.** If you need captured
  context, pass it as part of the message instead of closing over it.
- **Prefer `coroutine()` over `actor()` for one-shot work.** `coroutine()`
  reuses a shared executor isolate; spawning a fresh `actor()` per job pays
  isolate-startup cost every time for no benefit once the work is done.
- **Dispose actors you spawn.** `Actor` implements `Disposable` — an
  undisposed `actor()` leaves its isolate running for the life of the app.
  `Singleton`s are intentionally *not* disposed by application code; they
  live for the process's lifetime by design.
- **Don't invent a fourth `stub/io/web` variant ad hoc.** Follow the
  existing pattern (see `CLAUDE.md`) so platform selection stays consistent
  across the whole workspace.
