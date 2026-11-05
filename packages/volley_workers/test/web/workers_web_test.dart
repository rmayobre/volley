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
}
