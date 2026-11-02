import 'package:test/test.dart';
import 'package:volley_api/src/uuid/uuid_v4.dart';
import 'package:volley_api/src/uuid/uuid_v7.dart';

final _v4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);
final _v7 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  group('uuidV4', () {
    test('matches RFC 9562 v4 format', () {
      for (var i = 0; i < 100; i++) {
        expect(uuidV4(), matches(_v4));
      }
    });

    test('generates unique values', () {
      expect({for (var i = 0; i < 1000; i++) uuidV4()}, hasLength(1000));
    });
  });

  group('uuidV7', () {
    test('matches RFC 9562 v7 format', () {
      for (var i = 0; i < 100; i++) {
        expect(uuidV7(), matches(_v7));
      }
    });

    test('encodes the current millisecond timestamp in the first 48 bits', () {
      final before = DateTime.now().millisecondsSinceEpoch;
      final id = uuidV7();
      final after = DateTime.now().millisecondsSinceEpoch;
      final ms = int.parse(id.replaceAll('-', '').substring(0, 12), radix: 16);
      expect(ms, inInclusiveRange(before, after));
    });

    test('is sortable by creation time', () async {
      final first = uuidV7();
      await Future.delayed(const Duration(milliseconds: 5));
      final second = uuidV7();
      expect(first.compareTo(second), lessThan(0));
    });

    test('generates unique values', () {
      expect({for (var i = 0; i < 1000; i++) uuidV7()}, hasLength(1000));
    });
  });
}
