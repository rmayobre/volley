# invalid_actor_function

**Invalid `@actor` function** · Severity: Error · Enabled by default

An `@actor` is a non-generic top-level function that takes exactly one required positional `Message` and returns a `Message`, optionally in a `Future`.

## Why

The generator wraps the function in `spawn<Name>()` and `<name>WorkerMain()`. Both rely on a single input message type and a single output message type, and on the function being callable by name from a worker entrypoint, which is why it must be top-level and non-generic.

## Examples

### Triggers the rule

```dart
// workers.dart
import 'package:volley_workers/volley_workers.dart';

part 'workers.gen.dart';

@encodable
final class Ping implements Message {
  final String text;
  const Ping(this.text);
}

@encodable
final class Pong implements Message {
  final String text;
  const Pong(this.text);
}

@actor
Pong echo(Ping a, Ping b) => Pong(a.text);    // LINT: two parameters

@actor
Pong optional([Ping? a]) => Pong('');         // LINT: optional parameter

@actor
int count(Ping ping) => 1;                    // LINT: result is not a Message

@actor
Pong generic<T>(Ping ping) => Pong('');       // LINT: generic

class Host {
  @actor
  static Pong echo(Ping ping) => Pong('');    // LINT: not top-level
}
```

### Passes

```dart
// workers.dart
import 'package:volley_workers/volley_workers.dart';

part 'workers.gen.dart';

@encodable
final class Ping implements Message {
  final String text;
  const Ping(this.text);
}

@encodable
final class Pong implements Message {
  final String text;
  const Pong(this.text);
}

@actor
Future<Pong> echo(Ping ping) async => Pong(ping.text);

@actor
Pong shout(Ping ping) => Pong(ping.text.toUpperCase());
```

## How to fix

Fold several inputs into one `@encodable` message, make the function top-level, and return a `Message` (wrap a plain value in a small message class).

## Configuration

Silence one occurrence with `// ignore: volley_lints/invalid_actor_function`, or a whole file with
`// ignore_for_file: volley_lints/invalid_actor_function`. To turn the rule off for a project, set it
to `false` in `analysis_options.yaml`:

```yaml
plugins:
  volley_lints:
    diagnostics:
      invalid_actor_function: false
```

## Related rules

* [`invalid_coroutine_function`](invalid_coroutine_function.md)
* [`worker_unsupported_type`](worker_unsupported_type.md)
* [`unsendable_closure_capture`](unsendable_closure_capture.md)
