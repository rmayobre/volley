@TestOn('vm')
library;

import 'dart:isolate';

import 'package:test/test.dart';
import 'package:volley/volley.dart';

int _throwsState() => throw StateError('compute failed');

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

  group('coroutine failure across isolates', () {
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
  });
}
