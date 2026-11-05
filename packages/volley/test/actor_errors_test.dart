import 'dart:isolate';

import 'package:test/test.dart';
import 'package:volley/volley.dart';

final class Num implements Message {
  final int value;
  const Num(this.value);
}

Num _failOnNegative(Num m) {
  if (m.value < 0) throw ArgumentError('negative value: ${m.value}');
  return Num(m.value);
}

Future<Num> _failAsync(Num m) async {
  await Future.delayed(const Duration(milliseconds: 10));
  throw StateError('async failure');
}

// Kept in its own file (= its own test process) so a crashing actor can never
// affect unrelated tests.
void main() {
  setUpAll(() => Bootstrapper.initialize());

  group('Actor.closed', () {
    test('is pending while the actor is running', () async {
      final a = await actor<Num, Num>(_failOnNegative);
      addTearDown(a.dispose);

      var completed = false;
      a.closed.then((_) => completed = true);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(completed, isFalse);
    });

    test('completes with null after dispose', () async {
      final a = await actor<Num, Num>(_failOnNegative);
      a.dispose();
      expect(await a.closed.timeout(const Duration(seconds: 3)), isNull);
    });

    test('completes with the error when the reducer throws', () async {
      final a = await actor<Num, Num>(_failOnNegative);
      addTearDown(a.dispose);

      a.channel.send(const Num(-1));
      final error = await a.closed.timeout(const Duration(seconds: 3));

      expect(error, isA<RemoteError>());
      expect(error.toString(), contains('negative value: -1'));
    });

    test('captures errors thrown by asynchronous reducers', () async {
      final a = await actor<Num, Num>(_failAsync);
      addTearDown(a.dispose);

      a.channel.send(const Num(1));
      final error = await a.closed.timeout(const Duration(seconds: 3));
      expect(error.toString(), contains('async failure'));
    });

    test('a failed actor stops processing further messages', () async {
      final a = await actor<Num, Num>(_failOnNegative);
      addTearDown(a.dispose);

      final received = <Num>[];
      a.channel.messages.listen(received.add, onError: (_) {});

      a.channel.send(const Num(-1));
      await a.closed.timeout(const Duration(seconds: 3));
      try {
        a.channel.send(const Num(4));
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 200));
      expect(received, isEmpty);
    });

    test('closes the response stream when the actor fails', () async {
      final a = await actor<Num, Num>(_failOnNegative);
      addTearDown(a.dispose);

      final done = a.channel.messages.drain<void>();
      a.channel.send(const Num(-1));
      await done.timeout(const Duration(seconds: 3));
    });

    test('dispose after failure is harmless and keeps the error', () async {
      final a = await actor<Num, Num>(_failOnNegative);
      a.channel.send(const Num(-1));
      final error = await a.closed.timeout(const Duration(seconds: 3));

      a.dispose();
      expect(await a.closed, same(error));
    });

    test('a failing actor does not affect other actors', () async {
      final bad = await actor<Num, Num>(_failOnNegative);
      final good = await actor<Num, Num>(_failOnNegative);
      addTearDown(bad.dispose);
      addTearDown(good.dispose);

      bad.channel.send(const Num(-1));
      await bad.closed.timeout(const Duration(seconds: 3));

      final reply = good.channel.messages.first;
      good.channel.send(const Num(3));
      expect((await reply.timeout(const Duration(seconds: 3))).value, 3);

      var goodClosed = false;
      good.closed.then((_) => goodClosed = true);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(goodClosed, isFalse);
    });
  });
}
