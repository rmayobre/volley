# Changelog

## 0.1.0

- Analyzer plugin with eleven rules for `volley_workers` code: unsupported
  `@encodable` properties, invalid `@encodable`/`@actor`/`@coroutine`/
  `@singleton` declarations, unsendable worker types, missing generated
  `part`, native-only imports in worker libraries, and closures that capture
  unsendable values. See `doc/rules/`.
