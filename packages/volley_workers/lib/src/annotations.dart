/// Annotations read by `volley_workers_gen`: `@actor`, `@coroutine`,
/// `@singleton` and `@encodable`.
library;

/// The type of [actor]; use the constant, not this class.
final class ActorWorker {
  /// Creates the annotation.
  const ActorWorker();
}

/// Marks a top-level function as an actor.
///
/// The function must take a single `Message` parameter and return a `Message`
/// response (`M`, `Future<M>` or `FutureOr<M>`). `volley_workers_gen`
/// generates `spawn<Name>` and `<name>WorkerMain` for it.
const actor = ActorWorker();

/// The type of [coroutine]; use the constant, not this class.
final class CoroutineWorker {
  /// Creates the annotation.
  const CoroutineWorker();
}

/// Marks a top-level function as a coroutine worker.
///
/// The function may return any type (`T`, `Future<T>` or `FutureOr<T>`) and
/// take parameters of any type supported by web workers. `volley_workers_gen`
/// generates `launch<Name>` and `<name>WorkerMain` for it.
const coroutine = CoroutineWorker();

/// The type of [encodable]; use the constant, not this class.
final class Encodable {
  /// Creates the annotation.
  const Encodable();
}

/// Marks a `Message` class so `volley_workers_gen` generates `_$NameToMap` /
/// `_$NameFromMap` codecs for it, letting it cross a web worker boundary.
const encodable = Encodable();

/// The type of [singleton]; use the constant, not this class.
final class SingletonWorker {
  /// Creates the annotation.
  const SingletonWorker();
}

/// Marks a `Singleton` subclass so web workers can use it.
///
/// The singleton always lives on the page (or in the VM's shared host);
/// workers reach it by message passing. `volley_workers_gen` generates
/// `register<Name>()` and `request<Name>(message)`: `request<Name>` works
/// everywhere (page, worker, VM) and returns the reply to that call.
const singleton = SingletonWorker();
