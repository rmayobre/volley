# volley_workers

Web Worker backed actors and coroutines for [volley](../volley), built on the
`volley_api` interfaces. On the VM the same code runs on isolates through
`volley`. Use it with [`volley_workers_gen`](../volley_workers_gen), which
generates the plumbing from annotated functions.

```dart
import 'package:volley_workers/volley_workers.dart';

part 'workers.gen.dart';

@encodable
final class Ping implements Message {
  final String text;
  const Ping(this.text);
}

@encodable
final class Pong implements Message {
  final String text;
  const Pong(this.text);
}

@actor
Future<Pong> echo(Ping ping) async => Pong(ping.text.toUpperCase());

@coroutine
Future<int> sum(List<int> values) async => values.fold<int>(0, (a, b) => a + b);
```

`dart run build_runner build` generates `workers.gen.dart` with
`spawnEcho()` (returns an `Actor<Pong, Ping>`), `launchSum(values)` (returns a
`Coroutine<int>`), and `echoWorkerMain()` / `sumWorkerMain()`.

## Web workers

Each worker needs its own entrypoint that calls the generated `*WorkerMain`:

```dart
// echo_worker.dart
import 'workers.dart';
void main() => echoWorkerMain();
```

Compile it and pass its URL as `workerScript` (default `echo.worker.js`):

```
dart compile js -o echo.worker.js echo_worker.dart
```

Actor messages and coroutine arguments/results cross the worker boundary as
JS-safe values. `@encodable` classes get generated codecs; coroutines
accept primitives, lists, maps, typed data, enums, `DateTime`, `Duration`,
`BigInt`, `RegExp` and message classes.

## Singletons

Annotate a `Singleton` subclass with `@singleton` to share it with workers. On
the web the instance lives on the page and workers reach it by message
passing; on the VM every isolate shares one instance.

```dart
@singleton
final class Counter extends SerializedSingleton<Total, Add> { ... }

@actor
Future<Total> accumulate(Add add) => requestCounter(add);
```

See `example/` and `test/` (browser tests need the worker scripts compiled first
and must be run from this directory: `dart test -p chrome test/web`).

See the [architecture overview](../../docs/architecture.md).
