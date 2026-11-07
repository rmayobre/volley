# Changelog

## 0.1.0

- Initial release.
- `@actor` and `@coroutine` functions run as isolates on the VM or Web Workers
  in the browser; `@singleton` lets workers reach page-owned singletons;
  `@encodable` marks messages that get generated codecs.
