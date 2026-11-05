import 'dart:async';

import 'package:test/test.dart';
import 'package:volley/volley.dart';

void main() {
  setUpAll(() => Bootstrapper.initialize());

  test('disposing an outer coroutine while it awaits a nested one', () async {
    final outer = coroutine(
      () => coroutine(() => Completer<String>().future).result,
    );
    final failure = expectLater(
      outer.result,
      throwsA(isA<CoroutineDisposedException>()),
    );
    await Future.delayed(const Duration(milliseconds: 100));
    outer.dispose();
    await failure;
    expect(await coroutine(() => 'still works').result, 'still works');
  });

  test('dispose called immediately after creation cancels cleanly', () async {
    final c = coroutine(() => Completer<int>().future);
    final failure = expectLater(
      c.result,
      throwsA(isA<CoroutineDisposedException>()),
    );
    c.dispose();
    await failure;
    expect(await coroutine(() => 7).result, 7);
  });
}
