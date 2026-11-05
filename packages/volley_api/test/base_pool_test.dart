import 'package:test/test.dart';
import 'package:volley_api/volley_api.dart';

void main() {
  group('BasePool', () {
    test('borrows and releases resources across sequential calls', () async {
      final pool = Pool<int>(1, (index) => index);
      final first = await pool.execute((resource) async => resource + 1);
      final second = await pool.execute((resource) async => resource + 1);
      expect(first, equals(1));
      expect(second, equals(1));
      expect(pool.available, equals(1));
    });

    test(
      'propagates an internal-operation error as a catchable exception',
      () async {
        // Regression test: BasePool dispatches borrow/release through a
        // StreamController whose listener can throw (e.g. the resource
        // factory failing, or the release-overflow guard in
        // _handleOperation). With an async controller, that throw escapes
        // as an unhandled Zone error instead of surfacing at the execute()
        // call site. With `sync: true` (the fix), it surfaces synchronously
        // and rejects execute()'s returned Future normally.
        final pool = Pool<int>(
          1,
          (index) => throw StateError('factory failed'),
        );

        await expectLater(
          pool.execute((resource) async => resource),
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}
