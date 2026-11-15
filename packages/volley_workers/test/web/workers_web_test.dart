@TestOn('browser')
library;

import 'package:test/test.dart';

import '../../example/workers.dart';

// One script serves every worker; it is compiled from the generated
// entrypoint, which picks the worker by the name the spawn function gives it:
//   dart compile js -O1 -o test/web/workers.worker.js example/workers.worker.dart
void main() {
  test('generated actor runs in a web worker', () async {
    final a = await spawnEcho(workerScript: 'workers.worker.js');
    addTearDown(a.dispose);
    final reply = a.channel.messages.first;
    a.channel.send(Ping('hi', numbers: const [1, 2, 3], at: DateTime(2020)));
    final pong = await reply;
    expect(pong.text, 'HI');
    expect(pong.total, 6);
  });

  test('generated coroutine runs in a web worker', () async {
    final c = launchSum([1, 2, 3], 10, workerScript: 'workers.worker.js');
    expect(await c.result, 16);
    expect(c.isDone, isTrue);
  });

  test('workers and the page share one page-owned singleton', () async {
    final a = await spawnAccumulate(workerScript: 'workers.worker.js');
    addTearDown(a.dispose);
    final first = a.channel.messages.first;
    a.channel.send(const Add(5));
    expect((await first).value, 5);

    final c = launchBump(2, workerScript: 'workers.worker.js');
    expect(await c.result, 7);

    // The page sees the state the workers built up.
    expect((await requestCounter(const Add(1))).value, 8);

    final second = a.channel.messages.first;
    a.channel.send(const Add(10));
    expect((await second).value, 18);
  });
}
