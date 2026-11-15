# unsendable_closure_capture

**Closure captures a value that cannot be sent** · Severity: Warning · Enabled by default

A function literal passed to `actor()` or `coroutine()` runs in another isolate, so it must not capture streams, controllers, sockets, ports, futures, functions or volley handles.

## Why

On the VM, `actor(reducer)` and `coroutine(compute)` send the function to a new isolate together with everything it closes over. A captured `StreamController`, `Socket`, `Actor`, `Channel`, `Disposable`, `Future`, `Timer` or function value cannot be copied across the isolate boundary, so the call fails at runtime (often only when the closure first runs). Capturing plain data (numbers, strings, lists of those, messages) is fine, and so is a top-level or static function. The rule reports each such captured variable once.

## Examples

### Triggers the rule

```dart
import 'dart:async';
import 'package:volley/volley.dart';

void start(StreamController<int> sink, void Function(String) log) {
  coroutine(() {
    sink.add(1);      // LINT: StreamController
    log('done');      // LINT: a function
    return 1;
  });
}
```

### Passes

```dart
import 'package:volley/volley.dart';

// A top-level function captures nothing.
int work(int n) => n * 2;

Future<void> start(void Function(int) report, int n) async {
  // Capturing sendable values is fine; handle the result on this side.
  final result = await coroutine(() => work(n)).result;
  report(result);
}
```

## How to fix

Pass a top-level or static function, capture only sendable values, and do the work with the unsendable value on the calling side (for example, await `Coroutine.result` and then call the callback).

## Configuration

Silence one occurrence with `// ignore: volley_lints/unsendable_closure_capture`, or a whole file with
`// ignore_for_file: volley_lints/unsendable_closure_capture`. To turn the rule off for a project, set it
to `false` in `analysis_options.yaml`:

```yaml
plugins:
  volley_lints:
    diagnostics:
      unsendable_closure_capture: false
```

## Related rules

* [`invalid_actor_function`](invalid_actor_function.md)
