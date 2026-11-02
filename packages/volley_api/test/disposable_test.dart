import 'dart:async';

import 'package:test/test.dart';
import 'package:volley_api/volley_api.dart';

void main() {
  group('Disposables', () {
    test('disposes every member, mixing sync and async disposers', () async {
      final log = <String>[];
      final group = Disposable.iterables([
        Disposable(() => log.add('sync')),
        Disposable(() async {
          await Future.delayed(const Duration(milliseconds: 5));
          log.add('async');
        }),
      ]);
      await group.dispose();
      expect(log, unorderedEquals(['sync', 'async']));
    });

    test('asDisposable on an iterable groups its members', () async {
      var count = 0;
      await [
        Disposable(() => count++),
        Disposable(() => count++),
      ].asDisposable().dispose();
      expect(count, 2);
    });

    test('handles an empty collection', () async {
      await Disposable.iterables(const []).dispose();
    });
  });

  group('autoDispose / use', () {
    test('returns the process result and disposes afterwards', () async {
      var disposed = false;
      final d = Disposable(() => disposed = true);
      final result = await autoDispose(() {
        expect(disposed, isFalse);
        return 42;
      }, d);
      expect(result, 42);
      expect(disposed, isTrue);
    });

    test('disposes even when the process throws, and rethrows', () async {
      var disposed = false;
      final d = Disposable(() => disposed = true);
      await expectLater(
        autoDispose<int>(() => throw StateError('boom'), d),
        throwsStateError,
      );
      expect(disposed, isTrue);
    });

    test('use passes the disposable to the callback', () async {
      var disposed = false;
      final d = Disposable(() => disposed = true);
      final seen = await d.use((x) => x);
      expect(seen, same(d));
      expect(disposed, isTrue);
    });
  });

  group('DisposableSubscription', () {
    test('dispose cancels the underlying subscription', () async {
      var canceled = false;
      final controller = StreamController<int>(onCancel: () => canceled = true);
      final received = <int>[];
      final sub = controller.stream.listen(received.add).asDisposable();

      controller.add(1);
      await Future.delayed(Duration.zero);
      await sub.dispose();
      expect(canceled, isTrue);
      expect(received, [1]);
    });

    test('delegates pause and resume', () async {
      final controller = StreamController<int>();
      final received = <int>[];
      final sub = controller.stream.listen(received.add).asDisposable();

      sub.pause();
      expect(sub.isPaused, isTrue);
      controller.add(1);
      await Future.delayed(Duration.zero);
      expect(received, isEmpty);

      sub.resume();
      expect(sub.isPaused, isFalse);
      await Future.delayed(Duration.zero);
      expect(received, [1]);
      await sub.dispose();
    });

    test('delegates onData replacement', () async {
      final controller = StreamController<int>();
      final first = <int>[], second = <int>[];
      final sub = controller.stream.listen(first.add).asDisposable();
      sub.onData(second.add);
      controller.add(7);
      await Future.delayed(Duration.zero);
      expect(first, isEmpty);
      expect(second, [7]);
      await sub.dispose();
    });
  });
}
