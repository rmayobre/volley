/// Helpers used by `@encodable`-generated `toMap()`/`fromMap()` code
/// (see `MapEncodableMessage`) to encode types that `jsify()`/`dartify()`
/// don't understand natively — [RegExp] and [BigInt] — into values built
/// entirely out of types they do (`String`, `bool`).
library;

Map<String, Object?> regExpToMap(RegExp value) => {
  'pattern': value.pattern,
  'multiLine': value.isMultiLine,
  'caseSensitive': value.isCaseSensitive,
  'unicode': value.isUnicode,
  'dotAll': value.isDotAll,
};

RegExp regExpFromMap(Map<String, Object?> map) => RegExp(
  map['pattern'] as String,
  multiLine: map['multiLine'] as bool? ?? false,
  caseSensitive: map['caseSensitive'] as bool? ?? true,
  unicode: map['unicode'] as bool? ?? false,
  dotAll: map['dotAll'] as bool? ?? false,
);

String bigIntToMap(BigInt value) => value.toString();

BigInt bigIntFromMap(Object? value) => BigInt.parse(value as String);
