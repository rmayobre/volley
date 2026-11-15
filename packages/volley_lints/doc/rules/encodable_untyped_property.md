# encodable_untyped_property

**Untyped property in an `@encodable` class** · Severity: Warning · Enabled by default

Avoid `Object` and `dynamic` constructor parameters in `@encodable` classes: their contents are not checked until runtime.

## Why

For `Object` and `dynamic` the generator passes the value through unchecked, so it cannot tell whether the value can cross a worker boundary. A value that cannot (a closure, a custom class, a `Map<int, _>`) is only discovered when the message is posted, and surfaces as an `UnsendableMessageException`, possibly only on the web, since `postMessage` has the strict rules. A concrete type moves that failure to analysis time.

## Examples

### Triggers the rule

```dart
// workers.dart
import 'package:volley_workers/volley_workers.dart';

part 'workers.gen.dart';

@encodable
final class Event implements Message {
  final String name;
  final Object payload;   // LINT
  final dynamic extra;    // LINT
  const Event(this.name, this.payload, this.extra);
}
```

### Passes

```dart
// workers.dart
import 'package:volley_workers/volley_workers.dart';

part 'workers.gen.dart';

@encodable
final class Event implements Message {
  final String name;
  final Map<String, String> payload;
  final List<int> extra;
  const Event(this.name, this.payload, this.extra);
}
```

## How to fix

Replace `Object`/`dynamic` with the concrete type, or with a small `@encodable` class (one per kind of payload). If the value is genuinely free-form JSON, `Map<String, Object?>` is still checked at runtime only; silence the rule on that line with `// ignore: volley_lints/encodable_untyped_property`.

## Configuration

Silence one occurrence with `// ignore: volley_lints/encodable_untyped_property`, or a whole file with
`// ignore_for_file: volley_lints/encodable_untyped_property`. To turn the rule off for a project, set it
to `false` in `analysis_options.yaml`:

```yaml
plugins:
  volley_lints:
    diagnostics:
      encodable_untyped_property: false
```

## Related rules

* [`encodable_unsupported_property`](encodable_unsupported_property.md)
