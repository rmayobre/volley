# encodable_unsupported_property

**Unsupported property in an `@encodable` class** · Severity: Error · Enabled by default

Every constructor parameter of an `@encodable` class must have a type that can cross a web worker boundary.

## Why

`@encodable` generates `toMap`/`fromMap` codecs so a message can be sent to a Web Worker. Web workers only transfer `null`, `bool`, numbers, `String`, typed data and `List`/`Map` of those, so the generator converts a few richer types (`DateTime`, `Duration`, `BigInt`, `RegExp`, enums, other `@encodable` classes). Anything else (functions, streams, sockets, arbitrary classes, `Map` with non-`String` keys) has no wire form, and `build_runner` fails. This rule reports the problem on the offending parameter while you type.

Supported types: `null`, `bool`, `int`, `double`, `num`, `String`, `dart:typed_data` types, `BigInt`, `RegExp`, `DateTime`, `Duration`, enums, `List`/`Set`/`Iterable` of supported types, `Map<String, V>` with a supported `V`, `@encodable` classes, and `MapEncodableMessage` classes that provide `fromMap`. `Object` and `dynamic` are accepted but see [`encodable_untyped_property`](encodable_untyped_property.md).

## Examples

### Triggers the rule

```dart
// workers.dart
import 'package:volley_workers/volley_workers.dart';

part 'workers.gen.dart';

class Settings {} // not @encodable

@encodable
final class Job implements Message {
  final void Function() onDone;      // LINT: a function
  final Map<int, String> namesById;  // LINT: keys must be String
  final List<Stream<int>> feeds;     // LINT: Stream inside a List
  final Settings settings;           // LINT: Settings is not @encodable
  const Job(this.onDone, this.namesById, this.feeds, this.settings);
}
```

### Passes

```dart
// workers.dart
import 'package:volley_workers/volley_workers.dart';

part 'workers.gen.dart';

@encodable
final class Settings implements Message {
  final bool verbose;
  const Settings(this.verbose);
}

@encodable
final class Job implements Message {
  final String name;
  final Map<String, String> namesById; // String keys
  final List<int> samples;             // plain data instead of a Stream
  final Settings settings;             // @encodable
  final DateTime? deadline;            // converted by the generator
  const Job(this.name, this.namesById, this.samples, this.settings, this.deadline);
}
```

## How to fix

Change the type to a supported one, annotate the class with `@encodable`, or remove the parameter. Callbacks and streams cannot be sent; send the data they would carry, or model the callback as a reply message.

## Configuration

Silence one occurrence with `// ignore: volley_lints/encodable_unsupported_property`, or a whole file with
`// ignore_for_file: volley_lints/encodable_unsupported_property`. To turn the rule off for a project, set it
to `false` in `analysis_options.yaml`:

```yaml
plugins:
  volley_lints:
    diagnostics:
      encodable_unsupported_property: false
```

## Related rules

* [`invalid_encodable_class`](invalid_encodable_class.md)
* [`encodable_untyped_property`](encodable_untyped_property.md)
* [`worker_unsupported_type`](worker_unsupported_type.md)
