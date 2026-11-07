/// Annotations read by `volley_workers_gen`.
///
/// Put them on declarations in a library that has `part 'name.gen.dart';`,
/// then run `dart run build_runner build`:
///
/// * [actor] on a function: generates `spawn<Name>()` and `<name>WorkerMain()`.
/// * [coroutine] on a function: generates `launch<Name>()` and
///   `<name>WorkerMain()`.
/// * [encodable] on a message class: generates its `toMap` / `fromMap` codecs.
/// * [singleton] on a `Singleton` subclass: generates `register<Name>()` and
///   `request<Name>()`.
library;

/// The type of [actor]. Use the [actor] constant rather than constructing it.
final class ActorWorker {
  /// Creates the annotation. Prefer the [actor] constant.
  const ActorWorker();
}

/// Marks a top-level function as an actor that runs in an isolate (VM) or a
/// web worker (web).
///
/// The function takes exactly one `Message` and returns a `Message`, either
/// directly or in a `Future`/`FutureOr`. Both message types must be
/// [encodable] (or implement `MapEncodableMessage` with a `fromMap`) so they
/// can cross a web worker boundary.
///
/// ```dart
/// @actor
/// Future<Pong> echo(Ping ping) async => Pong(ping.text);
/// ```
///
/// generates `Future<Actor<Pong, Ping>> spawnEcho({String workerScript})` and
/// `void echoWorkerMain()`. The latter is the entrypoint to call from the
/// `main` of the web worker script (see the package README).
const actor = ActorWorker();

/// The type of [coroutine]. Use the [coroutine] constant rather than
/// constructing it.
final class CoroutineWorker {
  /// Creates the annotation. Prefer the [coroutine] constant.
  const CoroutineWorker();
}

/// Marks a top-level function as a one-shot coroutine that runs in an isolate
/// (VM) or a web worker (web).
///
/// The function takes required positional parameters of any type a web worker
/// can receive (see [encodable] for message classes) and returns a value of
/// such a type, directly or in a `Future`/`FutureOr`.
///
/// ```dart
/// @coroutine
/// Future<int> sum(List<int> values) async => values.fold(0, (a, b) => a + b);
/// ```
///
/// generates `Coroutine<int> launchSum(List<int> values, {String workerScript})`
/// and `void sumWorkerMain()`.
const coroutine = CoroutineWorker();

/// The type of [encodable]. Use the [encodable] constant rather than
/// constructing it.
final class Encodable {
  /// Creates the annotation. Prefer the [encodable] constant.
  const Encodable();
}

/// Marks a message class so `volley_workers_gen` generates the codecs that let
/// it cross a web worker boundary.
///
/// The class must implement `Message` and be concrete and non-generic, with an
/// unnamed constructor. Every constructor parameter needs a public name and a
/// field or getter of the same name, and a type the generator can convert:
/// `null`, `bool`, numbers, `String`, typed data, `BigInt`, `RegExp`,
/// `DateTime`, `Duration`, enums, `List`/`Set`/`Iterable`, `Map<String, V>`,
/// other [encodable] classes and `MapEncodableMessage` classes with a
/// `fromMap`.
///
/// ```dart
/// @encodable
/// final class Ping implements Message {
///   final String text;
///   const Ping(this.text);
/// }
/// ```
///
/// generates top-level `_$PingToMap` and `_$PingFromMap` functions. The
/// codecs are functions, not members, so the class does not implement
/// `MapEncodableMessage` itself.
const encodable = Encodable();

/// The type of [singleton]. Use the [singleton] constant rather than
/// constructing it.
final class SingletonWorker {
  /// Creates the annotation. Prefer the [singleton] constant.
  const SingletonWorker();
}

/// Marks a `Singleton` subclass so web workers can use it.
///
/// The class must extend `SerializedSingleton` or `ConcurrentSingleton`, be
/// concrete and non-generic, and have an unnamed constructor with no required
/// parameters (the instance is built without arguments). Its input and output
/// message types must be [encodable].
///
/// The singleton always lives on the page (or in the VM's shared host);
/// workers reach it by message passing. For a class `Counter` the generator
/// writes:
///
/// * `void registerCounter()`: makes it reachable from workers. The generated
///   `spawn*` and `launch*` functions of the same library call it for you; call
///   it yourself on the page when a worker in another library uses `Counter`.
/// * `Future<O> requestCounter(I message)`: sends a message and returns the
///   reply to that call. It works on the page, in a worker and on the VM.
const singleton = SingletonWorker();
