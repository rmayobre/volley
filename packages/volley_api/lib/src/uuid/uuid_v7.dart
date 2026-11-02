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
String uuidV7() {
  final ms = DateTime.now().millisecondsSinceEpoch;
  final rng = Random.secure();
  final bytes = Uint8List(16);

  // 48-bit Unix timestamp (big-endian)
  bytes[0] = (ms >> 40) & 0xFF;
  bytes[1] = (ms >> 32) & 0xFF;
  bytes[2] = (ms >> 24) & 0xFF;
  bytes[3] = (ms >> 16) & 0xFF;
  bytes[4] = (ms >> 8) & 0xFF;
  bytes[5] = ms & 0xFF;

  // version nibble (0x7) + 12-bit rand_a
  final randA = rng.nextInt(0x1000);
  bytes[6] = 0x70 | (randA >> 8);
  bytes[7] = randA & 0xFF;

  // 62-bit rand_b with variant bits (0b10) in the high two bits of byte 8
  for (var i = 8; i < 16; i++) {
    bytes[i] = rng.nextInt(256);
  }
  bytes[8] = 0x80 | (bytes[8] & 0x3F);

  return '${hex(bytes, 0, 4)}'
      '-${hex(bytes, 4, 2)}'
      '-${hex(bytes, 6, 2)}'
      '-${hex(bytes, 8, 2)}'
      '-${hex(bytes, 10, 6)}';
}
