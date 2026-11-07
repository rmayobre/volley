/// Isolate and Web Worker backed actors and coroutines for volley.
///
/// Annotate functions with [actor] and [coroutine], message classes with
/// [encodable] and singletons with [singleton], then run `build_runner` with
/// `volley_workers_gen`. The generated code calls the runtime exported here:
/// on the VM it runs on isolates through `volley`; on the web it runs in Web
/// Workers. See the package README and `docs/architecture.md`.
library;

export 'package:volley/volley.dart'
    show ConcurrentSingleton, SerializedSingleton, Singleton;
export 'package:volley_api/volley_api.dart';

export 'src/annotations.dart';
export 'src/worker_runtime.dart';
export 'src/singleton_registry.dart' show registerSingleton;
