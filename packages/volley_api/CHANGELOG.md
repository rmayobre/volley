## 0.1.0

- `Message`, `DistinctMessage` (UUIDv4 `id`), `MapEncodableMessage` and the
  RegExp/BigInt map codecs, `UnsendableMessageException`.
- `Channel<I, O>` (`IngressChannel<I>` receives, `EgressChannel<O>` sends) and
  `Actor<I, O>`. An actor's reducer is `FutureOr<I> Function(O)`: it consumes
  `O` and produces `I`, so its `channel` is a `Channel<I, O>` from the caller's
  side.
- `Actor.closed`: a `Future<Object?>` that completes when the actor closes,
  with `null` after `dispose()` or with the error if the actor failed.
- `Coroutine<R>` and `CoroutineDisposedException`.
- `MessageBus` / `BaseMessageBus` and the `subscribe`/`proxyInto` extensions.
- `Disposable`, `Disposables`, `DisposableSubscription`, `autoDispose` / `use`.
- `Pool<T>` / `BasePool<T>`: a fixed-size, lazily filled pool. `Pool` is
  `Disposable`: disposing fails waiting callers with `PoolDisposedException`
  and disposes `Disposable` resources (in-use ones when handed back). A
  resource factory that throws no longer uses up a pool slot.
- `uuidV4` / `uuidV7` helpers. `uuidV7` writes its timestamp correctly on the
  web (dart2js bit shifts are 32-bit).

## 0.0.1

- Initial version: the `Actor`, `Channel`, `Coroutine`, `Disposable`,
  `MessageBus` and `Pool` interfaces.
