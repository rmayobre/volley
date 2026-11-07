# volley_api

Shared interfaces for the [`volley`](../volley) concurrency framework. This
package is **pure API surface** — no implementation, no platform-specific
code (no `dart:isolate`, no `dart:js_interop`), so it's safe to depend on
from anywhere, including code that itself needs to stay platform-agnostic
(e.g. message definitions shared between an app and its workers).

If you're implementing `volley` itself or an extension of it (for example a
backend built on real Web Workers), this is the package whose contracts you
implement against. If you're just using `volley` in an app, you'll mostly interact
with these types indirectly, through `volley`'s exports.

## Core types

- **`Message`** — marker interface (`@immutable`) for anything sent through
  a `Channel`/`Actor`. Your request/response/event types implement this.
- **`Actor<I, O>`** — a running unit of concurrency: something that consumes
  `O` and produces `I` (a `Channel<I, O>` from the caller's side: receive
  `I`, send `O`), and can be `dispose()`d. `Actor.closed` completes when it
  closes, with the error if it failed.
- **`Channel<I, O>`** — bidirectional: `IngressChannel<I>` (`Stream<I>
  messages`) + `EgressChannel<O>` (`void send(O message)`).
- **`Coroutine<R>`** — a one-shot computation with `result`, `isRunning`,
  `isDone`, `isCanceled`; `CoroutineDisposedException` is what `result` fails
  with when it is disposed first.
- **`Disposable`** / **`Disposables`** — a `dispose()` contract, plus
  `Disposable.iterables(...)` to bundle several into one.
- **`MessageBus`** / **`BaseMessageBus`** — pub/sub fan-out over a stream of
  `Message`s, for wiring multiple listeners to one channel.
- **`Pool<T>`** / **`BasePool<T>`** — a fixed-size, lazily filled pool of
  reusable objects. `dispose()` fails waiting callers (and later calls) with
  `PoolDisposedException` and disposes `Disposable` resources, idle ones now
  and in-use ones when handed back.

## Making a `Message` safe to send across a worker/isolate boundary

- **`DistinctMessage`** — a mixin giving a message a unique `id` (a UUIDv4),
  for matching replies to requests.
- **`MapEncodableMessage`** — the interface a message implements to encode
  itself (`Map<String, Object?> toMap()`) using only types that `jsify()` /
  `dartify()` understand. An implementation that sends messages over a
  JS-interop boundary (such as real Web Workers) can use `toMap()` instead of
  relying on `jsify()`'s undefined behavior for arbitrary custom classes.
  `regExpToMap`/`regExpFromMap` and `bigIntToMap`/`bigIntFromMap` help encode
  the types `jsify()` can't. (`volley_workers` itself uses generated top-level
  codecs for `@encodable` classes rather than this interface.)
- **`UnsendableMessageException`** — thrown at runtime (for example by
  `volley`'s isolate channel) when a message fails to cross the boundary,
  instead of letting the raw platform error leak through.

[`volley_workers_gen`](../volley_workers_gen) is a code generator that targets
`Message` and `UnsendableMessageException`; no generator is bundled here.

## Best practices

- **Keep messages immutable and data-only.** `Message` is `@immutable`;
  don't put mutable fields, `Function`-typed properties, or open handles
  (streams, sinks, ports) on a message — none of those can cross an isolate
  or worker boundary.
- **Implement `MapEncodableMessage` if a message might cross a real Web
  Worker.** A hand-written `Message` class works fine on native (Dart's
  isolate-copy handles arbitrary object graphs) but has *undefined* behavior
  over `jsify()` on web.
- **Don't add platform imports here.** This package's entire value is being
  safely importable from anywhere; a stray `dart:io` or `dart:js_interop`
  import defeats that for every downstream consumer. Platform-specific
  behavior belongs in `volley`'s own `stub/io/web` split.
- **Depend on the interfaces, not on `volley`.** If you're writing code that
  should work against any `volley`-shaped backend (tests, alternate
  implementations), import `volley_api` directly rather than pulling in
  `volley` just for its re-exported types.
