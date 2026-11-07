# Changelog

## 0.1.0

- Initial release.
- Generates `foo.gen.dart` with `spawn*`/`launch*`/`*WorkerMain` for `@actor`
  and `@coroutine`, `register*`/`request*` for `@singleton`, and codecs for
  `@encodable`, with build-time validation of the annotated declarations.
