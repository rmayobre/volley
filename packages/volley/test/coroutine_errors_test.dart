import 'dart:async';
import 'dart:isolate';

import 'package:test/test.dart';
import 'package:volley/volley.dart';

final class CustomFailure implements Exception {
  final String reason;
  const CustomFailure(this.reason);
}

int _throwsState() => throw StateError('compute failed');

Future<int> _throwsAsync() async {
  await Future.delayed(const Duration(milliseconds: 10));
  throw const CustomFailure('async reason');
}

int _throwsUnsendable() {
  // A ReceivePort cannot be sent across isolates.
  throw _Unsendable(ReceivePort());
}

final class _Unsendable implements Exception {
  final ReceivePort port;
  _Unsendable(this.port);

  @override
  String toString() => '_Unsendable(port)';
}

void main() {
  setUpAll(() => Bootstrapper.initialize());

  group('coroutine failure', () {
    test('rejects result with the original error type and message', () async {
      final c = coroutine(_throwsState);
      await expectLater(
        c.result.timeout(const Duration(seconds: 3)),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'compute failed',
          ),
        ),
      );
    });

    test('preserves custom exception types and fields', () async {
      await expectLater(
        coroutine(_throwsAsync).result.timeout(const Duration(seconds: 3)),
        throwsA(
          isA<CustomFailure>().having(
            (e) => e.reason,
            'reason',
            'async reason',
          ),
        ),
      );
    });

    test('carries a stack trace from the computation', () async {
      try {
        await coroutine(
          _throwsState,
        ).result.timeout(const Duration(seconds: 3));
        fail('expected an error');
      } catch (e, st) {
        expect(e, isA<StateError>());
        expect(st.toString(), contains('_throwsState'));
      }
    });

    test('falls back to RemoteError when the error is not sendable', () async {
      await expectLater(
        coroutine(_throwsUnsendable).result.timeout(const Duration(seconds: 3)),
        throwsA(
          isA<RemoteError>().having(
            (e) => e.toString(),
            'description',
            contains('_Unsendable'),
          ),
        ),
      );
    });

    test('marks the coroutine as settled, not running', () async {
      final c = coroutine(_throwsState);
      await c.result.then<void>((_) {}, onError: (_) {});
      expect(c.isRunning, isFalse);
      expect(c.isCanceled, isFalse);
    });

    test('propagates a nested coroutine failure to the outer one', () async {
      final outer = coroutine(() => coroutine(_throwsState).result);
      await expectLater(
        outer.result.timeout(const Duration(seconds: 3)),
        throwsA(isA<StateError>()),
      );
    });

    test('a failure does not affect other concurrent coroutines', () async {
      final bad = coroutine(_throwsState);
      final good = coroutine(() => 'fine');
      final badOutcome = expectLater(bad.result, throwsA(isA<StateError>()));
      expect(await good.result, 'fine');
      await badOutcome;
    });

    test('the executor keeps working after failures', () async {
      for (var i = 0; i < 3; i++) {
        await coroutine(
          _throwsState,
        ).result.then<void>((_) {}, onError: (_) {});
      }
      expect(await coroutine(() => 'still works').result, 'still works');
    });

    test('dispose after failure is a no-op', () async {
      final c = coroutine(_throwsState);
      await c.result.then<void>((_) {}, onError: (_) {});
      c.dispose();
      expect(c.isCanceled, isFalse);
    });
  });
}
