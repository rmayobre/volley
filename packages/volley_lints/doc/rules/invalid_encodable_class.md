# invalid_encodable_class

**Invalid `@encodable` class** · Severity: Error · Enabled by default

`@encodable` classes must be concrete, non-generic `Message`s with an unnamed constructor whose parameters match fields or getters.

## Why

The generator builds `_$NameToMap` and `_$NameFromMap` from the class's unnamed constructor, reading each parameter's value back through a field or getter of the same name. It therefore needs:

* the class to implement `Message`;
* no type parameters;
* a concrete class (not `abstract`);
* an unnamed constructor;
* public parameter names (a `_private` name cannot be used as a named argument or read from outside);
* a field or getter named like each constructor parameter.

Each violation is reported on the class name, or on the offending parameter.

## Examples

### Triggers the rule

```dart
// workers.dart
import 'package:volley_workers/volley_workers.dart';

part 'workers.gen.dart';

@encodable
final class NotAMessage {              // LINT: must implement Message
  const NotAMessage();
}

@encodable
final class Box<T> implements Message { // LINT: generic
  const Box();
}

@encodable
abstract class Shape implements Message {} // LINT: abstract

@encodable
final class Counter implements Message {
  final int _count;
  const Counter(this._count);          // LINT: private parameter name
}

@encodable
final class Job implements Message {
  const Job(int priority);             // LINT: no field or getter `priority`
}
```

### Passes

```dart
// workers.dart
import 'package:volley_workers/volley_workers.dart';

part 'workers.gen.dart';

@encodable
final class Counter implements Message {
  final int count;
  const Counter(this.count);
}

@encodable
final class Job implements Message {
  final int priority;
  const Job(this.priority);
}

@encodable
final class Rect implements Message {
  final int width;
  final int height;
  int get area => width * height; // a getter is fine, it is just not sent
  const Rect(this.width, this.height);
}
```

## How to fix

Make the class concrete and non-generic, implement `Message`, give every constructor parameter a public name and a matching field or getter. For a polymorphic message hierarchy, annotate each concrete subclass instead of the abstract base.

## Configuration

Silence one occurrence with `// ignore: volley_lints/invalid_encodable_class`, or a whole file with
`// ignore_for_file: volley_lints/invalid_encodable_class`. To turn the rule off for a project, set it
to `false` in `analysis_options.yaml`:

```yaml
plugins:
  volley_lints:
    diagnostics:
      invalid_encodable_class: false
```

## Related rules

* [`encodable_unsupported_property`](encodable_unsupported_property.md)
* [`encodable_ignored_field`](encodable_ignored_field.md)
* [`missing_generated_part`](missing_generated_part.md)
