# volley_api

Shared interfaces for the [`volley`](../volley) concurrency framework. This
package is **pure API surface** — no implementation, no platform-specific
code (no `dart:isolate`, no `dart:js_interop`), so it's safe to depend on
from anywhere, including code that itself needs to stay platform-agnostic
(e.g. message definitions shared between an app and its workers).

If you're implementing `volley` itself or an extension of it (like
`volley_workers`), this is the package whose contracts you implement
against. If you're just using `volley` in an app, you'll mostly interact
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
- **`Disposable`** / **`Disposables`** — a `dispose()` contract, plus
  `Disposable.iterables(...)` to bundle several into one.
- **`MessageBus`** / **`BaseMessageBus`** — pub/sub fan-out over a stream of
  `Message`s, for wiring multiple listeners to one channel.
- **`Pool<T>`** / **`BasePool<T>`** — a reusable-object pool abstraction.

## Making a `Message` safe to send across a worker/isolate boundary

- **`MapEncodableMessage`** — the interface a message implements to encode
  itself (`Map<String, Object?> toMap()`). `WorkerChannel`/`WorkerAdapter` in
  `volley_workers` use `toMap()` automatically when sending a message that
  implements it, instead of relying on `jsify()`'s undefined behavior for
  arbitrary custom classes.
- **`UnsendableMessageException`** — thrown at runtime (by `volley`'s
  isolate channel and `volley_workers`' worker channel alike) when a message
  fails to cross the boundary, instead of letting the raw platform error
  leak through.
- **`@volleyMessage`** — the annotation that generates a `MapEncodableMessage`
  implementation for you. It lives in
  [`volley_workers`](../volley_workers) (alongside `@ActorWorker`/
  `@CoroutineWorker`), and its builder lives in
  [`volley_workers_gen`](../volley_workers_gen) — this package only supplies
  the `Message` interface and `MapEncodableMessage`/`UnsendableMessageException`
  the generated code targets, not the annotation itself.

```dart
import 'package:volley_api/volley_api.dart';
import 'package:volley_workers/volley_workers.dart';

@volleyMessage
abstract interface class EchoRequest implements Message {
  String get text;
  int get count;
}
```

See `volley_workers_gen`'s README for the generated output and the full list
of supported property types.

## Best practices

- **Keep messages immutable and data-only.** `Message` is `@immutable`;
  don't put mutable fields, `Function`-typed properties, or open handles
  (streams, sinks, ports) on a message — none of those can cross an isolate
  or worker boundary.
- **Reach for `@volleyMessage` as soon as a message might cross a real Web
  Worker.** A hand-written `Message` class works fine on native (Dart's
  isolate-copy handles arbitrary object graphs) but has *undefined* behavior
  over `jsify()` on web — don't wait for a bug report to add the annotation.
- **Don't add platform imports here.** This package's entire value is being
  safely importable from anywhere; a stray `dart:io` or `dart:js_interop`
  import defeats that for every downstream consumer. Platform-specific
  behavior belongs in `volley`/`volley_workers`' own `stub/io/web` split.
- **Depend on the interfaces, not on `volley`.** If you're writing code that
  should work against any `volley`-shaped backend (tests, alternate
  implementations), import `volley_api` directly rather than pulling in
  `volley` just for its re-exported types.
