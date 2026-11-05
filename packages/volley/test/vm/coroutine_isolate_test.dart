@TestOn('vm')
library;

import 'dart:isolate';

import 'package:test/test.dart';
import 'package:volley/volley.dart';

void main() {
  setUpAll(() => Bootstrapper.initialize());

  group('coroutine', () {
    test('runs in a different isolate than the caller', () async {
      final callerHash = Isolate.current.hashCode;
      final workerHash = await coroutine(() => Isolate.current.hashCode).result;
      expect(workerHash, isNot(callerHash));
    });
  });
}
