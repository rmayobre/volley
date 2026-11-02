import 'message.dart';

/// A [Message] that can encode itself to/from a JSON-like [Map].
///
/// `jsify()`/`dartify()` (`dart:js_interop`) only have defined conversions
/// for `null`, `bool`, `num`, `String`, `List`, `Map`, and `dart:typed_data`
/// types — calling `jsify()` on an arbitrary custom class instance is
/// undefined behavior. [toMap] produces a value built entirely out of those
/// supported types, so `toMap().jsify()` is well-defined even when the
/// message itself holds types that aren't ([RegExp], [BigInt], enums, or
/// nested [MapEncodableMessage] types).
///
/// Generated automatically for `@volleyMessage`-annotated classes by
/// `package:volley_workers_gen`, which also generates a matching top-level
/// `fromMap` function per class to reverse the conversion.
abstract interface class MapEncodableMessage implements Message {
  Map<String, Object?> toMap();
}
