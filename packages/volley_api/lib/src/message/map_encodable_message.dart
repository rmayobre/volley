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
/// `@encodable` classes processed by `package:volley_workers_gen` do *not*
/// implement this interface: the generator emits top-level `_$NameToMap` /
/// `_$NameFromMap` functions instead. The generator also accepts fields whose
/// type implements this interface, provided it has a `fromMap` factory or
/// static method.
abstract interface class MapEncodableMessage implements Message {
  /// Encodes this message as a map of JS-interop-safe values.
  Map<String, Object?> toMap();
}
