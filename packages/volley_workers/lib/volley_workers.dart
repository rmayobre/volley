/// Isolate and Web Worker backed actors and coroutines for volley.
library;

export 'package:volley/volley.dart'
    show ConcurrentSingleton, SerializedSingleton, Singleton;
export 'package:volley_api/volley_api.dart';

export 'src/annotations.dart';
export 'src/worker_runtime.dart';
export 'src/singleton_registry.dart' show registerSingleton;
