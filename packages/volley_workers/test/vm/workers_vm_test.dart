@TestOn('vm')
library;

import 'package:test/test.dart';

import '../../example/workers.dart';

void main() {
  test('generated actor runs in an isolate', () async {
    final a = await spawnEcho();
    addTearDown(a.dispose);
    final reply = a.channel.messages.first;
    a.channel.send(const Ping('hi', numbers: [1, 2, 3]));
    final pong = await reply;
    expect(pong.text, 'HI');
    expect(pong.total, 6);
  });

  test('generated coroutine runs in an isolate', () async {
    expect(await launchSum([1, 2, 3], 10).result, 16);
  });

  test('actors, coroutines and the caller share one singleton', () async {
    final a = await spawnAccumulate();
    addTearDown(a.dispose);
    final reply = a.channel.messages.first;
    a.channel.send(const Add(5));
    expect((await reply).value, 5);

    expect(await launchBump(2).result, 7);
    expect((await requestCounter(const Add(1))).value, 8);
  });
}
