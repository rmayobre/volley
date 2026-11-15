# volley_lints

An [analyzer plugin](https://dart.dev/tools/analyzer-plugins) for
[volley](../..). It reports semantic mistakes in `volley_workers` code in your
IDE and in `dart analyze`, before you run `build_runner` (or the app on the
web, where some of them only fail at runtime).

```dart
@encodable
final class Job implements Message {
  final void Function() onDone; // error: 'onDone' cannot be sent to a worker
  const Job(this.onDone);
}
```

## Setup

Requires Dart 3.13 or newer (the plugin tracks the analyzer that ships with the
SDK). Add the plugin to the top-level `plugins` section of your
`analysis_options.yaml`, then restart the analysis server:

```yaml
plugins:
  volley_lints: ^0.1.0
```

Working on volley itself, or trying an unpublished version? Point at a path:

```yaml
plugins:
  volley_lints:
    path: packages/volley_lints
```

All rules are enabled by default. To disable one for a project:

```yaml
plugins:
  volley_lints:
    diagnostics:
      encodable_untyped_property: false
```

To silence a single occurrence, or a whole file:

```dart
// ignore: volley_lints/encodable_untyped_property
final Object payload;

// ignore_for_file: volley_lints/worker_library_imports_native
```

## Rules

Each rule has a page with the reasoning, code that triggers it, code that
passes, and how to fix it.

| Rule | Severity | Reports |
| --- | --- | --- |
| [`encodable_unsupported_property`](doc/rules/encodable_unsupported_property.md) | error | An `@encodable` constructor parameter whose type cannot cross a worker boundary (functions, streams, `Map<int, _>`, classes that are not `@encodable`, ...). |
| [`invalid_encodable_class`](doc/rules/invalid_encodable_class.md) | error | An `@encodable` class that is not a concrete, non-generic `Message` with an unnamed constructor and matching fields/getters. |
| [`encodable_untyped_property`](doc/rules/encodable_untyped_property.md) | warning | `Object` / `dynamic` in an `@encodable` class: contents are only checked at runtime. |
| [`encodable_ignored_field`](doc/rules/encodable_ignored_field.md) | warning | A field that is not a constructor parameter, so it is not sent to the worker. |
| [`invalid_actor_function`](doc/rules/invalid_actor_function.md) | error | An `@actor` that is not a non-generic top-level function from one `Message` to a `Message`. |
| [`invalid_coroutine_function`](doc/rules/invalid_coroutine_function.md) | error | A `@coroutine` that is generic, not top-level, or has optional/named parameters. |
| [`invalid_singleton_class`](doc/rules/invalid_singleton_class.md) | error | A `@singleton` that is abstract, generic, has required constructor parameters, or does not extend a volley `Singleton`. |
| [`worker_unsupported_type`](doc/rules/worker_unsupported_type.md) | error | A parameter, result or singleton message type in a worker signature that cannot be sent. |
| [`missing_generated_part`](doc/rules/missing_generated_part.md) | error | An annotated library without `part '<file>.gen.dart';`. |
| [`worker_library_imports_native`](doc/rules/worker_library_imports_native.md) | warning | `dart:io`, `dart:isolate`, `dart:ffi` or `dart:mirrors` imported by a library that declares workers. |
| [`unsendable_closure_capture`](doc/rules/unsendable_closure_capture.md) | warning | A closure passed to `actor()` / `coroutine()` that captures a stream, controller, socket, future, function or volley handle. |

Messages being immutable is already covered by the analyzer's own
`must_be_immutable` warning (`Message` is `@immutable`), so there is no rule
for it here.

## How it relates to `volley_workers_gen`

The generator validates the same shapes at build time and fails with an
`InvalidGenerationSourceError`. This plugin gives you those errors as you type,
and adds checks the generator cannot do (untyped fields, ignored fields,
closure captures, native imports). The type rules in
[`lib/src/semantics.dart`](lib/src/semantics.dart) mirror `Codec` in
`volley_workers_gen`; if you change one, change the other.

## Developing

```sh
dart pub get
dart test
```

Rule tests use `analyzer_testing` against small stand-ins for the volley
packages (`test/stubs.dart`). To try the plugin in a real project, point the
`path:` form above at this directory and restart the analysis server.

Adding a rule: write it in `lib/src/rules/`, register it in `lib/main.dart`,
add tests, and add a page in `doc/rules/` plus a row in the table above. Keep
the examples on that page compiling: every "Triggers the rule" example should
report exactly the rule, and every "Passes" example should be clean.
