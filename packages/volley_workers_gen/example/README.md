# volley_workers_gen example

A complete, runnable setup lives in the repository:

* [`packages/volley_workers/example`](https://github.com/rmayobre/volley/tree/main/packages/volley_workers/example)
  has annotated actors, coroutines, messages and a singleton, with the
  generated `workers.gen.dart`.
* [`examples/flutter_workers`](https://github.com/rmayobre/volley/tree/main/examples/flutter_workers)
  is a Flutter app that builds the generated code into web workers.

In short: add `volley_workers` as a dependency and `volley_workers_gen` plus
`build_runner` as dev dependencies, put `part 'foo.gen.dart';` in a library
with `@actor`, `@coroutine`, `@encodable` or `@singleton` declarations, and run

```
dart run build_runner build
```
