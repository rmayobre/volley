# Changelog

## 0.1.0

- Builder that writes `<file>.gen.dart` (a `part` file) for `@actor`,
  `@coroutine`, `@encodable` and `@singleton` declarations.
- Generates `spawn<Name>` / `launch<Name>`, web worker entrypoints
  (`<name>WorkerMain`), `toMap`/`fromMap` codecs and singleton
  `register<Name>` / `request<Name>`.
- Fails the build with a source-located error for unsupported shapes: wrong
  actor signatures, named or optional coroutine parameters, types a web worker
  cannot receive, and message constructor parameters without a matching field.
