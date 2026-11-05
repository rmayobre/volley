# volley_workers architecture

`volley_workers` and `volley_workers_gen` add Web Worker support to volley and
let one annotated function become an actor or coroutine that runs as a native
isolate **or** a web worker, from a single generated file.

## Package roles

| Package | Role |
| --- | --- |
| `volley_api` | Interfaces only: `Actor`, `Channel`, `Coroutine`, `Message`, `MapEncodableMessage`, `map_codecs`. No platform imports. |
| `volley` | Base implementation. Isolate-backed `actor()` / `coroutine()` on the VM; in-process on the web. |
| `volley_workers` | Runtime and annotations. Delegates to `volley` on the VM and to real Web Workers on the web. |
| `volley_workers_gen` | `build_runner` builder that reads the annotations and writes `foo.gen.dart`. Depends on `volley_workers` only to recognise its annotations by name. |

```
volley_api  <--  volley  <--  volley_workers
                                   ^   (annotations, runtime)
                                   |
                         volley_workers_gen   (build time only;
                         emits code that calls volley_workers)
```

## Build-time flow

```
foo.dart  (@actor / @coroutine / @volleyMessage, `part 'foo.gen.dart';`)
   |  build_runner -> PartBuilder([WorkersGenerator()], '.gen.dart')
   v
foo.gen.dart  (`part of 'foo.dart'`)
   per @volleyMessage class: _$NameToMap / _$NameFromMap
   per @actor fn:            spawn<Fn>()   + <fn>WorkerMain()
   per @coroutine fn:        launch<Fn>()  + <fn>WorkerMain()
```

`build.yaml` registers the builder with `build_extensions: {".dart":
[".gen.dart"]}`, `build_to: source`, so generated files are checked in next to
their sources. One source file yields one generated file.

The generator is split in two:

- `lib/src/workers_generator.dart` finds annotated elements, validates their
  shape and emits the code.
- `lib/src/codecs.dart` (`Codec`) turns a Dart type into encode/decode
  expressions for the wire form and rejects types it cannot convert.

### Validation

Errors surface as `InvalidGenerationSourceError` pointing at the element.

- `@actor`: top-level, non-generic, exactly one required positional parameter
  that is a `Message`, returning a `Message` (optionally in `Future`/`FutureOr`).
- `@coroutine`: top-level, non-generic, required positional parameters only;
  every parameter type and the result type must be convertible.
- `@volleyMessage`: concrete, non-generic class with an unnamed constructor.
  Each constructor parameter needs a public name and a matching field or getter;
  its type must be convertible.

Convertible types: `null`, `bool`, `int`, `double`, `num`, `String`,
`dart:typed_data` types, `BigInt`, `RegExp`, `DateTime`, `Duration`, enums,
`List`/`Set`/`Iterable`, `Map<String, V>`, `@volleyMessage` classes, and
`MapEncodableMessage` classes that provide `fromMap`. `Object` and `dynamic`
pass through unchecked.

Known limits: contents of `Object`/`dynamic` are only validated at runtime
(`postMessage` throws, surfaced as `UnsendableMessageException`); `int` values
above 2^53 lose precision on the web; fields that are not constructor
parameters are ignored. The stricter web rules are enforced on the VM too, so
the same code works on both.

## Runtime

Conditional exports select the implementation, as in `volley`:

```
lib/src/worker_runtime.dart
  export 'stub/worker_runtime.dart'
    if (dart.library.io)         'io/worker_runtime.dart'
    if (dart.library.js_interop) 'web/worker_runtime.dart';
```

### VM (`src/io`)

`spawnActorWorker` and `launchCoroutineWorker` call `volley`'s `actor()` and
`coroutine()`. Messages cross the isolate boundary as-is; the codecs and
`workerScript` are ignored. The `*WorkerMain` functions are web-only and throw
`UnsupportedError` here.

### Web (`src/web`)

Each actor or coroutine owns one `web.Worker` running a script compiled from a
tiny entrypoint that calls the generated `<fn>WorkerMain()`.

```
host                                   worker
 | new Worker(workerScript)             |
 |<-------------- {t:'ready'} ----------|   handshake
 | {t:'msg', d:<map>}  (actor)  ------->|   reducer(decode(d))
 |<------------ {t:'msg', d:<map>} -----|   encode(result)
 | {t:'run', a:<list>} (coroutine) ---->|   run(decode(args))
 |<---------- {t:'result', v:<value>} --|
 |<---------- {t:'error',  e:<text>} ---|   failure, either kind
```

Payloads go through `jsify()` / `dartify()`, which is why everything must reduce
to null, bool, num, String, List, Map or typed data.

- **Ordering:** the worker side chains messages on a future queue, so an actor
  handles one message at a time, in order, like `IsolateActor`.
- **Actor:** `closed` completes with `null` on `dispose()` or with the error on
  a worker failure; the channel stream then ends. `dispose()` calls
  `Worker.terminate()`.
- **Coroutine:** `dispose()` terminates the worker and fails `result` with
  `CoroutineDisposedException`. Errors arrive as text, not stack traces.
- **Unsendable data:** an encoding or `postMessage` failure becomes
  `UnsendableMessageException`.

### Compiling workers

```dart
// echo_worker.dart
import 'workers.dart';
void main() => echoWorkerMain();
```

```
dart compile js -o echo.worker.js echo_worker.dart
```

Pass the URL as `workerScript` (default `<fn>.worker.js`). The builder cannot
emit these entrypoints itself because a builder must declare its outputs up
front and only produces one `.gen.dart` per source file.

## Testing

| Location | What it covers |
| --- | --- |
| `volley_workers_gen/test` | Builder output and validation errors, via `build_test`. |
| `volley_workers/test/vm` | Generated actor and coroutine on isolates. |
| `volley_workers/test/web` | Generated actor and coroutine in Chrome. Needs the worker scripts compiled first (see the test file) and must be run from `packages/volley_workers`: `dart test -p chrome test/web`. |

`example/workers.gen.dart` is checked in so the example and tests compile
without running the builder.

## Limitations and future work

- Worker entrypoints are written by hand (two lines each).
- Coroutines accept required positional parameters only.
- Generated `@volleyMessage` codecs are top-level functions, not methods, so
  messages do not implement `MapEncodableMessage` automatically.
- No CI exists yet to compile the worker scripts before browser tests.
