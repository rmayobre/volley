import 'dart:async';

import 'package:test/test.dart';
import 'package:volley/volley.dart';

int _square(int n) => n * n;

Future<String> _slowValue() async {
  await Future.delayed(const Duration(milliseconds: 50));
  return 'slow';
}

Future<void> _neverFinishes() => Completer<void>().future;

void main() {
  setUpAll(() => Bootstrapper.initialize());

  group('coroutine', () {
    test('computes a synchronous value', () async {
      expect(await coroutine(() => 6 * 7).result, 42);
    });

    test('awaits an asynchronous computation', () async {
      expect(await coroutine(_slowValue).result, 'slow');
    });

    test('starts running and reports done on completion', () async {
      final c = coroutine(_slowValue);
      expect(c.isRunning, isTrue);
      expect(c.isDone, isFalse);
      expect(c.isCanceled, isFalse);

      await c.result;
      expect(c.isRunning, isFalse);
      expect(c.isDone, isTrue);
      expect(c.isCanceled, isFalse);
    });

    test('runs many coroutines concurrently with correct results', () async {
      final results = await Future.wait([
        for (var i = 0; i < 8; i++) coroutine(() => _square(i)).result,
      ]);
      expect(results, [for (var i = 0; i < 8; i++) i * i]);
    });

    test('supports nested coroutines', () async {
      final value =
          await coroutine(() => coroutine(() => 'inner').result).result;
      expect(value, 'inner');
    });

    test('dispose cancels a running coroutine', () async {
      final c = coroutine(_neverFinishes);
      final failure = expectLater(
        c.result,
        throwsA(isA<CoroutineDisposedException>()),
      );

      c.dispose();

      await failure;
      expect(c.isCanceled, isTrue);
      expect(c.isRunning, isFalse);
      expect(c.isDone, isFalse);
    });

    test('dispose after completion is a no-op', () async {
      final c = coroutine(() => 1);
      expect(await c.result, 1);
      c.dispose();
      expect(c.isCanceled, isFalse);
      expect(c.isDone, isTrue);
      expect(await c.result, 1);
    });

    test('disposing one coroutine does not affect others', () async {
      final doomed = coroutine(_neverFinishes);
      final survivor = coroutine(_slowValue);
      final failure = expectLater(doomed.result, throwsA(anything));
      doomed.dispose();
      await failure;
      expect(await survivor.result, 'slow');
    });

    test('executor remains usable after a cancellation', () async {
      final c = coroutine(_neverFinishes);
      final failure = expectLater(c.result, throwsA(anything));
      c.dispose();
      await failure;
      expect(await coroutine(() => 'ok').result, 'ok');
    });
  });
}
