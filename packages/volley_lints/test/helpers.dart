/// Offset of the first occurrence of [needle] in [source].
int at(String source, String needle) {
  final index = source.indexOf(needle);
  if (index < 0) throw StateError('"$needle" not found in:\n$source');
  return index;
}

/// The imports every test source starts with.
const header = "import 'package:volley_workers/volley_workers.dart';\n";
