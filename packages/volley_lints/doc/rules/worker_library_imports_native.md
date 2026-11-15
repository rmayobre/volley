# worker_library_imports_native

**Native-only import in a worker library** · Severity: Warning · Enabled by default

A library that declares workers is compiled to JavaScript for the web, so it should not import `dart:io`, `dart:isolate`, `dart:ffi` or `dart:mirrors`.

## Why

The same library is used on the VM and, compiled with `dart compile js`, as the entrypoint of a Web Worker. Importing a native-only library makes the web build fail or throw at runtime. Keep native code in a separate library that the worker library reaches through a conditional import, or in code that only runs on the VM side.

## Examples

### Triggers the rule

```dart
// workers.dart
import 'dart:io'; // LINT
import 'package:volley_workers/volley_workers.dart';

part 'workers.gen.dart';

@coroutine
Future<int> lineCount(String path) async =>
    (await File(path).readAsLines()).length;
```

### Passes

```dart
// workers.dart
import 'package:volley_workers/volley_workers.dart';

part 'workers.gen.dart';

// The file access lives in a library the worker does not import: the page
// reads the file and sends the text instead.
@coroutine
Future<int> lineCount(String text) async => text.split('\n').length;
```

## How to fix

Move the `dart:io` use out of the worker library: do the I/O on the page or VM side and pass the data in as an argument, or put it behind a conditional import (`import 'a.dart' if (dart.library.js_interop) 'b.dart';`).

## Configuration

Silence one occurrence with `// ignore: volley_lints/worker_library_imports_native`, or a whole file with
`// ignore_for_file: volley_lints/worker_library_imports_native`. To turn the rule off for a project, set it
to `false` in `analysis_options.yaml`:

```yaml
plugins:
  volley_lints:
    diagnostics:
      worker_library_imports_native: false
```

## Related rules

* [`missing_generated_part`](missing_generated_part.md)
