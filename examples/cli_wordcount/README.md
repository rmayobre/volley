# cli_wordcount

A command line example that uses `package:volley` only (isolates; no web
workers, no code generation).

```
dart pub get
dart run bin/main.dart ../../README.md ../../docs/architecture.md
```

It counts the words in each file you pass:

- `coroutine()` counts each file in its own isolate-backed job, all started
  before any is awaited so they run in parallel.
- `actor()` is a long-lived isolate that formats each result.
- A `SerializedSingleton` keeps the running total. `Singleton.request` returns
  the reply to each call.
- `Bootstrapper.shutdown()` at the end lets the process exit.

Because this example does not use `volley_workers`, it does not run in a
browser as real web workers. See [`../flutter_workers`](../flutter_workers) for
that.
