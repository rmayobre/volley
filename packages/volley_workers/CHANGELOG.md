# Changelog

## 0.1.0

- Annotations `@actor`, `@coroutine`, `@encodable` and `@singleton`, read by
  `volley_workers_gen`.
- Runtime for the generated code: on the VM it runs on `volley` isolates; on the
  web it runs in Web Workers (`package:web`) with a small message protocol.
- Web actors handle one message at a time, in order; disposing terminates the
  worker. Web coroutines fail `result` with `CoroutineDisposedException` when
  disposed.
- Page-owned singletons: workers reach `@singleton` classes through
  `request<Name>`, so every context shares one instance. `registerSingleton`
  exposes a singleton to workers.
