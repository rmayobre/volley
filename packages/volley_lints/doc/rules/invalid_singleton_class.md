# invalid_singleton_class

**Invalid `@singleton` class** · Severity: Error · Enabled by default

A `@singleton` is a concrete, non-generic `SerializedSingleton` or `ConcurrentSingleton` that can be built without arguments.

## Why

The generated `register<Name>()` builds the instance with `Name.new` and no arguments, on the page or in the VM's shared host, so the class needs an unnamed constructor with no required parameters. It must extend one of volley's `Singleton` base classes so it has the `reduce` method the runtime calls, and be concrete and non-generic so there is exactly one type to register.

## Examples

### Triggers the rule

```dart
// workers.dart
import 'package:volley_workers/volley_workers.dart';

part 'workers.gen.dart';

@encodable
final class Add implements Message {
  final int amount;
  const Add(this.amount);
}

@encodable
final class Total implements Message {
  final int value;
  const Total(this.value);
}

@singleton
final class Plain {}                                   // LINT: not a Singleton

@singleton
final class Counter extends SerializedSingleton<Total, Add> {
  final int start;
  Counter(this.start);                                 // LINT: required parameter
  @override
  Total reduce(Add event) => Total(start + event.amount);
}

@singleton
abstract class Base extends SerializedSingleton<Total, Add> {} // LINT: abstract
```

### Passes

```dart
// workers.dart
import 'package:volley_workers/volley_workers.dart';

part 'workers.gen.dart';

@encodable
final class Add implements Message {
  final int amount;
  const Add(this.amount);
}

@encodable
final class Total implements Message {
  final int value;
  const Total(this.value);
}

@singleton
final class Counter extends SerializedSingleton<Total, Add> {
  int _total = 0;

  @override
  Total reduce(Add event) => Total(_total += event.amount);
}
```

## How to fix

Extend `SerializedSingleton` or `ConcurrentSingleton`, make the class concrete and non-generic, and give the constructor optional or no parameters.

## Configuration

Silence one occurrence with `// ignore: volley_lints/invalid_singleton_class`, or a whole file with
`// ignore_for_file: volley_lints/invalid_singleton_class`. To turn the rule off for a project, set it
to `false` in `analysis_options.yaml`:

```yaml
plugins:
  volley_lints:
    diagnostics:
      invalid_singleton_class: false
```

## Related rules

* [`worker_unsupported_type`](worker_unsupported_type.md)
