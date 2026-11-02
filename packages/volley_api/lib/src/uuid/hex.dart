import 'dart:typed_data';

import 'package:meta/meta.dart';

@internal
String hex(Uint8List bytes, int start, int length) =>
    bytes
        .sublist(start, start + length)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
