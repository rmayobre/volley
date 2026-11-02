import 'dart:async';

import 'package:test/test.dart';
import 'package:volley_api/volley_api.dart';

void main() {
  group('Pool', () {
    test('reports size and lazily creates resources', () async {
      final created = <int>[];
      final pool = Pool<int>(3, (i) {
        created.add(i);
        return i;
      });
      expect(pool.size, 3);
      expect(pool.available, 0);
      expect(created, isEmpty);

      await pool.execute((_) {});
      expect(created, [0]);
      expect(pool.available, 1);
    });

    test('reuses a released resource rather than creating a new one', () async {
      var created = 0;
      final pool = Pool<int>(2, (_) => created++);
      await pool.execute((_) {});
      await pool.execute((_) {});
      expect(created, 1);
    });

    test('never creates more than size resources under concurrency', () async {
      var created = 0;
      var inUse = 0;
      var peak = 0;
      final pool = Pool<int>(2, (_) => created++);

      await Future.wait([
        for (var i = 0; i < 10; i++)
          Future(
            () => pool.execute<void>((_) async {
              peak = peak < ++inUse ? inUse : peak;
              await Future.delayed(const Duration(milliseconds: 2));
              inUse--;
            }),
          ),
      ]);

      expect(created, lessThanOrEqualTo(2));
      expect(peak, lessThanOrEqualTo(2));
      expect(pool.available, 2);
    });

    test('queued callers wait for a resource and are served FIFO', () async {
      final pool = Pool<int>(1, (i) => i);
      final gate = Completer<void>();
      final order = <String>[];

      final holder = Future(
        () => pool.execute<void>((_) async {
          order.add('holder');
          await gate.future;
        }),
      );
      final a = Future(() => pool.execute<void>((_) => order.add('a')));
      final b = Future(() => pool.execute<void>((_) => order.add('b')));

      await Future.delayed(const Duration(milliseconds: 5));
      expect(order, ['holder']);

      gate.complete();
      await Future.wait([holder, a, b]);
      expect(order, ['holder', 'a', 'b']);
    });

    test('returns the compute result for sync and async callbacks', () async {
      final pool = Pool<String>(1, (_) => 'r');
      expect(await pool.execute((r) => '$r-sync'), 'r-sync');
      expect(await pool.execute((r) async => '$r-async'), 'r-async');
    });

    test('releases the resource when compute throws', () async {
      final pool = Pool<int>(1, (i) => i);
      await expectLater(
        pool.execute<void>((_) => throw ArgumentError('bad')),
        throwsArgumentError,
      );
      expect(pool.available, 1);
      // Pool is still usable afterwards.
      expect(await pool.execute((r) => r), 0);
    });
  });
}
