# volley_workers_gen

Code generator for [`volley_workers`](../volley_workers). For a source file
`foo.dart` it writes `foo.gen.dart` (declare it with `part 'foo.gen.dart';`),
containing for each annotated function:

| Annotation | Requirements | Generated |
| --- | --- | --- |
| `@actor` | top-level function taking one `Message`, returning a `Message` (or `Future` of one) | `spawn<Name>()`, `<name>WorkerMain()` |
| `@coroutine` | top-level function, required positional parameters of any worker-transferable type, any return type | `launch<Name>(...)`, `<name>WorkerMain()` |
| `@volleyMessage` | concrete class with an unnamed constructor | `toMap` / `fromMap` codecs |

Add `volley_workers_gen` and `build_runner` as dev dependencies and run
`dart run build_runner build`.
