## 0.1.0

- `actor<I, O>(reducer)`: an isolate-backed actor on native platforms, a
  main-thread actor on the web. Messages are handled one at a time, in order.
  A reducer that throws closes the actor: `Actor.closed` completes with the
  error (a `RemoteError` on native). `actor()` throws instead of hanging if its
  isolate dies while starting.
- `coroutine<R>(compute)`: one-shot work on a shared executor isolate. A
  computation that throws fails `result` with the original error and stack
  trace (a `RemoteError` if the error can't cross isolates). Disposing a
  coroutine kills its work.
- `Singleton<I, O>` is sealed; extend `SerializedSingleton` (one message at a
  time, replies in send order) or `ConcurrentSingleton` (calls may overlap).
  Failures in `reduce` or in building a singleton are reported as error events
  on the channel stream (or as a thrown error from `Singleton.instance`) and no
  longer take down the shared singleton host.
- Type parameters follow `Channel`'s convention: `I` is what the caller
  receives and `O` is what it sends, for `Actor`, `Singleton` and
  `Singleton.instance`.
- `Bootstrapper.initialize()` is idempotent and concurrency-safe;
  `actor()` and `Singleton.instance()` call it for you.
  `Bootstrapper.shutdown()` stops the singleton host, kills unfinished
  coroutines and disposes `Disposable` singletons so a program can exit.
- Tests run on the VM and in Chrome (`test/common`, `test/vm`, `test/web`).

## 0.0.1

- Initial version: isolate-based actors, coroutines and singletons.
