# encodable_ignored_field

**Field ignored by an `@encodable` class** · Severity: Warning · Enabled by default

A field that is not a constructor parameter is not sent to the worker; the decoded copy will not have its value.

## Why

The generated codec only encodes constructor parameters. A field that is not a parameter (and is not derived in the constructor's initializer list or by an initializer) is silently dropped on the way through a worker, so the object on the other side behaves differently from the one that was sent. This is easy to miss on the VM, where messages cross isolates as-is, and then breaks on the web. Static fields, fields with an initializer, and fields set in the constructor's initializer list are not reported.

## Examples

### Triggers the rule

```dart
// workers.dart
import 'package:volley_workers/volley_workers.dart';

part 'workers.gen.dart';

@encodable
final class Report implements Message {
  final String title;
  String? cachedSummary;  // LINT: lost when the message is sent
  Report(this.title);
}
```

### Passes

```dart
// workers.dart
import 'package:volley_workers/volley_workers.dart';

part 'workers.gen.dart';

@encodable
final class Report implements Message {
  final String title;
  final String? summary;  // now part of the message
  const Report(this.title, this.summary);
}

// Or derive it, so nothing needs to be sent:
@encodable
final class Rect implements Message {
  final int width;
  final int height;
  final int area;
  const Rect(this.width, this.height) : area = width * height;
}
```

## How to fix

Add the field to the unnamed constructor, derive it from the parameters (initializer list or getter), or move cache state out of the message.

## Configuration

Silence one occurrence with `// ignore: volley_lints/encodable_ignored_field`, or a whole file with
`// ignore_for_file: volley_lints/encodable_ignored_field`. To turn the rule off for a project, set it
to `false` in `analysis_options.yaml`:

```yaml
plugins:
  volley_lints:
    diagnostics:
      encodable_ignored_field: false
```

## Related rules

* [`invalid_encodable_class`](invalid_encodable_class.md)
