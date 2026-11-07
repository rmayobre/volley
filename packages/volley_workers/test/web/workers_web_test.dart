@TestOn('browser')
library;

import 'package:test/test.dart';

import '../../example/workers.dart';

// The worker scripts are compiled from example/web_worker.dart and
// example/sum_worker.dart:
//   dart compile js -O1 -o test/web/echo.worker.js example/web_worker.dart
//   dart compile js -O1 -o test/web/sum.worker.js example/sum_worker.dart
void main() {
  test('generated actor runs in a web worker', () async {
    final a = await spawnEcho(workerScript: 'echo.worker.js');
    addTearDown(a.dispose);
    final reply = a.channel.messages.first;
    a.channel.send(Ping('hi', numbers: const [1, 2, 3], at: DateTime(2020)));
    final pong = await reply;
    expect(pong.text, 'HI');
    expect(pong.total, 6);
  });

  test('generated coroutine runs in a web worker', () async {
    final c = launchSum([1, 2, 3], 10, workerScript: 'sum.worker.js');
    expect(await c.result, 16);
    expect(c.isDone, isTrue);
  });

  test('workers and the page share one page-owned singleton', () async {
    final a = await spawnAccumulate(workerScript: 'accumulate.worker.js');
    addTearDown(a.dispose);
    final first = a.channel.messages.first;
    a.channel.send(const Add(5));
    expect((await first).value, 5);

    final c = launchBump(2, workerScript: 'bump.worker.js');
    expect(await c.result, 7);

    // The page sees the state the workers built up.
    expect((await requestCounter(const Add(1))).value, 8);

    final second = a.channel.messages.first;
    a.channel.send(const Add(10));
    expect((await second).value, 18);
  });
}
