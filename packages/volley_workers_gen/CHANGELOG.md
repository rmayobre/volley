# Changelog

## Unreleased

- Generates the web worker entrypoint `<file>.worker.dart` (a `main` that
  dispatches on the worker's name), so it no longer has to be written by hand.
  Compile it to `<file>.worker.js`.
- **Breaking:** the default `workerScript` is now `<file>.worker.js` instead of
  `<function>.worker.js`.

## 0.1.0

- Builder that writes `<file>.gen.dart` (a `part` file) for `@actor`,
  `@coroutine`, `@encodable` and `@singleton` declarations.
- Generates `spawn<Name>` / `launch<Name>`, web worker entrypoints
  (`<name>WorkerMain`), `toMap`/`fromMap` codecs and singleton
  `register<Name>` / `request<Name>`.
- Fails the build with a source-located error for unsupported shapes: wrong
  actor signatures, named or optional coroutine parameters, types a web worker
  cannot receive, and message constructor parameters without a matching field.
