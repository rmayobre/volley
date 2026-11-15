/// Code generation for `volley_workers`.
///
/// For a source file `foo.dart` that contains `@actor`, `@coroutine` or
/// `@encodable` declarations, generates `foo.gen.dart`. Declare it in the
/// source file with `part 'foo.gen.dart';`. When it has `@actor` or
/// `@coroutine` functions, also generates the web worker entrypoint
/// `foo.worker.dart`, whose `main` you compile to `foo.worker.js`.
library;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/entrypoint_builder.dart';
import 'src/workers_generator.dart';

/// Builder entry point referenced from `build.yaml`.
Builder workersBuilder(BuilderOptions options) =>
    PartBuilder([WorkersGenerator()], '.gen.dart');

/// Entrypoint builder referenced from `build.yaml`.
Builder workerEntrypointBuilder(BuilderOptions options) =>
    WorkerEntrypointBuilder();
