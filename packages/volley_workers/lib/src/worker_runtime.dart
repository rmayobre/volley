export 'stub/worker_runtime.dart'
    if (dart.library.io) 'io/worker_runtime.dart'
    if (dart.library.js_interop) 'web/worker_runtime.dart';
