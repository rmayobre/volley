/// Code generation for `volley_workers`.
///
/// For a source file `foo.dart` that contains `@actor`, `@coroutine` or
/// `@encodable` declarations, generates `foo.gen.dart`. Declare it in the
/// source file with `part 'foo.gen.dart';`.
library;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/workers_generator.dart';

/// Builder entry point referenced from `build.yaml`.
Builder workersBuilder(BuilderOptions options) =>
    PartBuilder([WorkersGenerator()], '.gen.dart');
