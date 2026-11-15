# invalid_coroutine_function

**Invalid `@coroutine` function** · Severity: Error · Enabled by default

A `@coroutine` is a non-generic top-level function with required positional parameters only.

## Why

The generated `launch<Name>(...)` repeats the function's parameters and serialises them positionally into the worker request, so optional and named parameters cannot be represented. The function must also be top-level and non-generic so the worker entrypoint can call it by name.

## Examples

### Triggers the rule

```dart
// workers.dart
import 'package:volley_workers/volley_workers.dart';

part 'workers.gen.dart';

@coroutine
int sum(List<int> values, {int offset = 0}) => offset;  // LINT: named

@coroutine
int first(List<int> values, [int fallback = 0]) => fallback; // LINT: optional

@coroutine
T pick<T>(List<int> values) => throw 'no';              // LINT: generic
```

### Passes

```dart
// workers.dart
import 'package:volley_workers/volley_workers.dart';

part 'workers.gen.dart';

@coroutine
Future<int> sum(List<int> values, int offset) async =>
    values.fold<int>(offset, (a, b) => a + b);
```

## How to fix

Make every parameter required and positional (pass defaults explicitly at the call site), and remove type parameters.

## Configuration

Silence one occurrence with `// ignore: volley_lints/invalid_coroutine_function`, or a whole file with
`// ignore_for_file: volley_lints/invalid_coroutine_function`. To turn the rule off for a project, set it
to `false` in `analysis_options.yaml`:

```yaml
plugins:
  volley_lints:
    diagnostics:
      invalid_coroutine_function: false
```

## Related rules

* [`invalid_actor_function`](invalid_actor_function.md)
* [`worker_unsupported_type`](worker_unsupported_type.md)
