/// Helpers used by `@encodable`-generated codecs and hand-written
/// `MapEncodableMessage` implementations to encode types that `jsify()`/`dartify()`
/// don't understand natively — [RegExp] and [BigInt] — into values built
/// entirely out of types they do (`String`, `bool`).
library;

/// Encodes [value], including its flags, as a map of `String`/`bool` values.
Map<String, Object?> regExpToMap(RegExp value) => {
  'pattern': value.pattern,
  'multiLine': value.isMultiLine,
  'caseSensitive': value.isCaseSensitive,
  'unicode': value.isUnicode,
  'dotAll': value.isDotAll,
};

/// Rebuilds a [RegExp] from the output of [regExpToMap].
RegExp regExpFromMap(Map<String, Object?> map) => RegExp(
  map['pattern'] as String,
  multiLine: map['multiLine'] as bool? ?? false,
  caseSensitive: map['caseSensitive'] as bool? ?? true,
  unicode: map['unicode'] as bool? ?? false,
  dotAll: map['dotAll'] as bool? ?? false,
);

/// Encodes [value] as its decimal string.
String bigIntToMap(BigInt value) => value.toString();

/// Parses a [BigInt] from the output of [bigIntToMap].
BigInt bigIntFromMap(Object? value) => BigInt.parse(value as String);
