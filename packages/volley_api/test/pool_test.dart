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

  group('Pool factory failure', () {
    test('a failing factory does not use up a slot', () async {
      var attempts = 0;
      final pool = Pool<int>(1, (i) {
        if (attempts++ == 0) throw StateError('first attempt fails');
        return i;
      });

      await expectLater(pool.execute((r) => r), throwsStateError);
      // Previously the failed attempt counted as created, so this waited
      // forever for a resource that did not exist.
      expect(
        await Future.value(
          pool.execute((r) => r),
        ).timeout(const Duration(seconds: 2)),
        0,
      );
    });
  });

  group('Pool dispose', () {
    test('execute after dispose throws PoolDisposedException', () async {
      final pool = Pool<int>(1, (i) => i);
      await pool.dispose();
      await expectLater(
        pool.execute((r) => r),
        throwsA(isA<PoolDisposedException>()),
      );
    });

    test(
      'callers waiting for a resource fail with PoolDisposedException',
      () async {
        final pool = Pool<int>(1, (i) => i);
        final gate = Completer<void>();
        final running = pool.execute<void>((_) => gate.future);
        final waiting = pool.execute((r) => r);
        final failure = expectLater(
          waiting,
          throwsA(isA<PoolDisposedException>()),
        );

        await Future.delayed(Duration.zero);
        await pool.dispose();
        await failure;

        gate.complete();
        await running; // the call that was already running still finishes
      },
    );

    test('disposes idle Disposable resources', () async {
      final made = <_Res>[];
      final pool = Pool<_Res>(2, (i) {
        final r = _Res(i);
        made.add(r);
        return r;
      });
      await Future.wait([
        Future.value(
          pool.execute<void>((_) => Future.delayed(Duration(milliseconds: 5))),
        ),
        Future.value(
          pool.execute<void>((_) => Future.delayed(Duration(milliseconds: 5))),
        ),
      ]);
      expect(made, hasLength(2));
      expect(made.every((r) => !r.disposed), isTrue);

      await pool.dispose();
      expect(made.every((r) => r.disposed), isTrue);
      expect(pool.available, 0);
    });

    test('a resource in use is disposed when it is handed back', () async {
      late _Res used;
      final pool = Pool<_Res>(1, (i) => _Res(i));
      final gate = Completer<void>();
      final running = pool.execute<void>((r) {
        used = r;
        return gate.future;
      });
      await Future.delayed(Duration.zero);

      await pool.dispose();
      expect(used.disposed, isFalse, reason: 'still in use');

      gate.complete();
      await running;
      await Future.delayed(Duration.zero);
      expect(used.disposed, isTrue);
      expect(pool.available, 0, reason: 'must not return to a closed pool');
    });

    test(
      'dispose is idempotent and ignores non-Disposable resources',
      () async {
        final pool = Pool<int>(2, (i) => i);
        await pool.execute((r) => r);
        await pool.dispose();
        await pool.dispose();
      },
    );
  });
}

final class _Res implements Disposable {
  final int index;
  bool disposed = false;
  _Res(this.index);

  @override
  void dispose() => disposed = true;
}
