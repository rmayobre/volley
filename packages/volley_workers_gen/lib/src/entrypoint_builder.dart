import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'workers_generator.dart';

/// Writes `foo.worker.dart` next to a `foo.dart` that declares `@actor` or
/// `@coroutine` functions: the web worker entrypoint, with a `main` that runs
/// whichever worker the page started.
///
/// Compile it with `dart compile js -o foo.worker.js foo.worker.dart`. One
/// script serves every worker of the library, selected by the `Worker` name.
final class WorkerEntrypointBuilder implements Builder {
  @override
  final buildExtensions = const {
    '.dart': ['.worker.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final input = buildStep.inputId;
    // Skip parts (`.gen.dart`) and entrypoints this builder already wrote.
    if (input.path.endsWith('.worker.dart') ||
        input.path.endsWith('.gen.dart') ||
        !await buildStep.resolver.isLibrary(input)) {
      return;
    }
    final library = LibraryReader(await buildStep.inputLibrary);
    final names = workerNames(library);
    if (names.isEmpty) return;

    final source = input.pathSegments.last;
    final entries = names.map((n) => "  '$n': ${n}WorkerMain,\n").join();
    await buildStep.writeAsString(
      input.changeExtension('.worker.dart'),
      '''
// GENERATED CODE - DO NOT MODIFY BY HAND
//
// Web worker entrypoint for $source. Compile it with:
//   dart compile js -O2 -o ${workerScriptBase(input)}.worker.js ${workerScriptBase(input)}.worker.dart

import 'package:volley_workers/volley_workers.dart';

import '$source';

void main() => runWorkerEntrypoint({
$entries});
''',
    );
  }
}
