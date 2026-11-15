# missing_generated_part

**Missing `part` directive for generated code** · Severity: Error · Enabled by default

A library with `@actor`, `@coroutine`, `@encodable` or `@singleton` declarations must declare `part '<file>.gen.dart';`.

## Why

`volley_workers_gen` writes `<file>.gen.dart` next to each annotated library as a `part of` file. Without the `part` directive the generated functions (`spawnEcho`, `_$PingToMap`, ...) are never part of the library, so the code that calls them does not compile after generation. The diagnostic names the expected file and is reported on the first annotation. Part files (`part of`) are not checked.

## Examples

### Triggers the rule

```dart
// workers.dart
import 'package:volley_workers/volley_workers.dart';

// LINT: no `part 'workers.gen.dart';`
@coroutine
Future<int> sum(List<int> values) async => values.length;
```

### Passes

```dart
// workers.dart
import 'package:volley_workers/volley_workers.dart';

part 'workers.gen.dart';

@coroutine
Future<int> sum(List<int> values) async => values.length;
```

## How to fix

Add the part directive (the file is named after the library file: `workers.dart` -> `workers.gen.dart`) and run `dart run build_runner build`.

## Configuration

Silence one occurrence with `// ignore: volley_lints/missing_generated_part`, or a whole file with
`// ignore_for_file: volley_lints/missing_generated_part`. To turn the rule off for a project, set it
to `false` in `analysis_options.yaml`:

```yaml
plugins:
  volley_lints:
    diagnostics:
      missing_generated_part: false
```

## Related rules

* [`invalid_encodable_class`](invalid_encodable_class.md)
