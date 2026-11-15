# worker_unsupported_type

**Worker signature uses a type that cannot be sent** · Severity: Error · Enabled by default

Parameters and results of `@actor` and `@coroutine` functions, and the message types of a `@singleton`, must be sendable to a web worker.

## Why

The generator has to encode every value that crosses the worker boundary, so it needs a wire form for each parameter, for the result (unwrapped from `Future`/`FutureOr`), and for a singleton's input and output messages. The most common cause is a message class that implements `Message` but is not `@encodable`. The diagnostic is reported on the offending parameter, return type, or type argument. See [`encodable_unsupported_property`](encodable_unsupported_property.md) for the list of supported types.

## Examples

### Triggers the rule

```dart
// workers.dart
import 'package:volley_workers/volley_workers.dart';

part 'workers.gen.dart';

final class Raw implements Message {  // missing @encodable
  const Raw();
}

@actor
Raw echo(Raw raw) => raw;             // LINT x2: parameter and result

@coroutine
Stream<int> numbers(int n) => throw 'no'; // LINT: Stream result

@singleton
final class Counter extends SerializedSingleton<Raw, Raw> { // LINT x2
  @override
  Raw reduce(Raw event) => event;
}
```

### Passes

```dart
// workers.dart
import 'package:volley_workers/volley_workers.dart';

part 'workers.gen.dart';

@encodable
final class Raw implements Message {
  const Raw();
}

@actor
Raw echo(Raw raw) => raw;

@coroutine
Future<List<int>> numbers(int n) async => [for (var i = 0; i < n; i++) i];

@singleton
final class Counter extends SerializedSingleton<Raw, Raw> {
  @override
  Raw reduce(Raw event) => event;
}
```

## How to fix

Annotate the message class with `@encodable`, or change the type to a supported one. Return a `List` instead of a `Stream`.

## Configuration

Silence one occurrence with `// ignore: volley_lints/worker_unsupported_type`, or a whole file with
`// ignore_for_file: volley_lints/worker_unsupported_type`. To turn the rule off for a project, set it
to `false` in `analysis_options.yaml`:

```yaml
plugins:
  volley_lints:
    diagnostics:
      worker_unsupported_type: false
```

## Related rules

* [`encodable_unsupported_property`](encodable_unsupported_property.md)
* [`invalid_actor_function`](invalid_actor_function.md)
