# Volley

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.svg">
  <img alt="Dart volley" src="assets/logo-light.svg" height=300 />
</picture>

A concurrency framework for Dart. It wraps isolates (on native platforms) and
the main thread (on the web) behind three small primitives with the same API on
both: **actors**, **coroutines** and **singletons**.

| Package | What it is |
|---|---|
| [`volley`](packages/volley) | The implementation: `actor()`, `coroutine()`, `Singleton`, `Bootstrapper`. |
| [`volley_api`](packages/volley_api) | Platform-agnostic interfaces and utilities (`Channel`, `Actor`, `Disposable`, `Pool`, `MessageBus`, ...). Re-exported by `volley`. |
| [`volley_workers`](packages/volley_workers) | Real Web Worker support: the same actors, coroutines and singletons run as isolates on the VM and as web workers in the browser. |
| [`volley_workers_gen`](packages/volley_workers_gen) | The `build_runner` generator for `volley_workers`: turns `@actor`, `@coroutine`, `@encodable` and `@singleton` declarations into one `.gen.dart` part file. |

How the worker packages fit together: [docs/architecture.md](docs/architecture.md).

## Examples

| Example | What it shows |
|---|---|
| [`examples/cli_wordcount`](examples/cli_wordcount) | A command line program using `volley` only: coroutines, an actor and a singleton on isolates. |
| [`examples/flutter_workers`](examples/flutter_workers) | A Flutter app using `volley_workers`: the same worker code runs as web workers on the web and as isolates elsewhere. |

Both are standalone packages (outside the repository's pub workspace) that use
path dependencies.

## A quick look

```dart
import 'package:volley/volley.dart';

final class Request implements Message {
  final int n;
  const Request(this.n);
}

final class Response implements Message {
  final int squared;
  const Response(this.squared);
}

// Reducers run in the actor's isolate, so they must be top-level functions.
Response square(Request r) => Response(r.n * r.n);

void main() async {
  // Actor: a dedicated isolate running one reducer.
  final a = await actor<Response, Request>(square);
  a.channel.messages.listen((r) => print('squared: ${r.squared}'));
  a.channel.send(const Request(7)); // squared: 49

  // Coroutine: one-shot work on a shared executor isolate.
  print(await coroutine(() => 6 * 7).result); // 42

  a.dispose();
  await Bootstrapper.shutdown(); // lets the program exit
}
```

Singletons (one shared, stateful instance per type, reachable from every
isolate) come in two flavours, `SerializedSingleton` and `ConcurrentSingleton`.
See the [`volley` README](packages/volley/README.md) for all of it, including
error handling, ordering guarantees and shutdown.

## Platforms

* **Native (VM):** real isolates.
* **Web:** everything runs on the main thread. The same code works, but
  nothing runs in parallel.

## Working in this repository

This is a Dart workspace. From the repository root:

```sh
dart pub get
dart analyze packages
dart test packages/volley_api packages/volley   # VM + Chrome (see below)
```

Each package's `dart_test.yaml` runs tests on the VM and in Chrome. Tests in
`packages/volley/test/` are organised by platform: `common/` runs on both,
`vm/` needs `dart:isolate`/`dart:io`, and `web/` needs the browser
implementations (selected with `@TestOn`). Use `dart test -p vm` where no
browser is installed.

See the [architecture overview](docs/architecture.md).
