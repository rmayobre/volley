import 'dart:math';
import 'dart:typed_data';

import 'hex.dart';

/// Generates a UUID version 7 string.
///
/// UUIDv7 is a time-ordered UUID (RFC 9562). The first 48 bits encode the
/// current Unix timestamp in milliseconds, making UUIDs naturally sortable.
///
/// Format: `xxxxxxxx-xxxx-7xxx-yxxx-xxxxxxxxxxxx`
/// - bits  0–47  : Unix timestamp (ms)
/// - bits 48–51  : version = 0x7
/// - bits 52–63  : rand_a (12 random bits)
/// - bits 64–65  : variant = 0b10
/// - bits 66–127 : rand_b (62 random bits)
/// Generates a UUID version 4 string.
///
/// UUIDv4 is a randomly generated UUID (RFC 9562). All 122 non-fixed bits
/// are filled with cryptographically secure random data.
///
/// Format: `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`
/// - bits 48–51 : version = 0x4
/// - bits 64–65 : variant = 0b10
/// - all other bits: random
String uuidV4() {
  final rng = Random.secure();
  final bytes = Uint8List(16);

  for (var i = 0; i < 16; i++) {
    bytes[i] = rng.nextInt(256);
  }

  // version nibble = 0x4
  bytes[6] = 0x40 | (bytes[6] & 0x0F);

  // variant bits = 0b10
  bytes[8] = 0x80 | (bytes[8] & 0x3F);

  return '${hex(bytes, 0, 4)}'
      '-${hex(bytes, 4, 2)}'
      '-${hex(bytes, 6, 2)}'
      '-${hex(bytes, 8, 2)}'
      '-${hex(bytes, 10, 6)}';
}
