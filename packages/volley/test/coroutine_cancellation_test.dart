import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:volley/volley.dart';

Future<void> _appendForever(String path) async {
  final file = File(path);
  while (true) {
    file.writeAsStringSync('x', mode: FileMode.append);
    await Future.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  setUpAll(() => Bootstrapper.initialize());

  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('volley_cancel_'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('dispose kills the running work (side effects stop)', () async {
    final path = '${dir.path}/out.txt';
    File(path).writeAsStringSync('');

    final c = coroutine(() => _appendForever(path));
    final failure = c.result.then<void>((_) {}, onError: (_) {});

    // Wait until the job is demonstrably running.
    for (var i = 0; i < 100 && File(path).lengthSync() == 0; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    expect(File(path).lengthSync(), greaterThan(0));

    c.dispose();
    await failure;
    // Let any in-flight write land, then confirm nothing more is written.
    await Future.delayed(const Duration(milliseconds: 200));
    final sizeAfterStop = File(path).lengthSync();
    await Future.delayed(const Duration(milliseconds: 300));
    expect(File(path).lengthSync(), sizeAfterStop);
  });

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
