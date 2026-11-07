/// Marks a top-level function as an actor.
///
/// The function must take a single [Message] parameter and return that
/// message type's response (`M`, `Future<M>` or `FutureOr<M>`) where the
/// response is also a [Message]. `volley_workers_gen` generates `spawn<Name>`
/// and `<name>WorkerMain` for it.
library;

/// See [actor].
final class ActorWorker {
  const ActorWorker();
}

/// Marks a top-level function as an actor worker.
const actor = ActorWorker();

/// See [coroutine].
final class CoroutineWorker {
  const CoroutineWorker();
}

/// Marks a top-level function as a coroutine worker.
///
/// The function may return any type (`T`, `Future<T>` or `FutureOr<T>`) and
/// take parameters of any type supported by web workers. `volley_workers_gen`
/// generates `launch<Name>` and `<name>WorkerMain` for it.
const coroutine = CoroutineWorker();

/// Marks a class as a message: `volley_workers_gen` generates `toMap` /
/// `fromMap` codecs for it so it can cross a web worker boundary.
final class Encodable {
  const Encodable();
}

/// Marks a class for `toMap` / `fromMap` generation.
const encodable = Encodable();

/// See [singleton].
final class SingletonWorker {
  const SingletonWorker();
}

/// Marks a `Singleton` subclass so web workers can use it.
///
/// The singleton always lives on the page (or in the VM's shared host);
/// workers reach it by message passing. `volley_workers_gen` generates
/// `register<Name>()` and `request<Name>(message)`: `request<Name>` works
/// everywhere (page, worker, VM) and returns the reply to that call.
const singleton = SingletonWorker();
