import 'dart:async';

import 'package:test/test.dart';
import 'package:volley/volley.dart';

final class Num implements Message {
  final int value;
  const Num(this.value);
}

final class Request implements Message {
  final int n;
  const Request(this.n);
}

final class Response implements Message {
  final String text;
  const Response(this.text);
}

// Reducers must be top-level so they can be sent to an isolate.
Num _double(Num m) => Num(m.value * 2);

Future<Num> _delayedIncrement(Num m) async {
  await Future.delayed(const Duration(milliseconds: 10));
  return Num(m.value + 1);
}

Num _failOnNegative(Num m) {
  if (m.value < 0) throw ArgumentError('negative value: ${m.value}');
  return Num(m.value);
}

Future<Num> _failAsync(Num m) async {
  await Future.delayed(const Duration(milliseconds: 10));
  throw StateError('async failure');
}

Response _toResponse(Request r) => Response('n=${r.n}');

void main() {
  setUpAll(() => Bootstrapper.initialize());

  const wait = Duration(seconds: 3);

  group('actor', () {
    test('applies the reducer to each message and emits the result', () async {
      final a = await actor<Num, Num>(_double);
      addTearDown(a.dispose);

      final first = a.channel.messages.first;
      a.channel.send(const Num(21));
      expect((await first).value, 42);
    });

    test('preserves response order for sequential messages', () async {
      final a = await actor<Num, Num>(_double);
      addTearDown(a.dispose);

      final results = a.channel.messages.take(5).map((m) => m.value).toList();
      for (var i = 1; i <= 5; i++) {
        a.channel.send(Num(i));
      }
      expect(await results.timeout(wait), [2, 4, 6, 8, 10]);
    });

    test('supports asynchronous reducers', () async {
      final a = await actor<Num, Num>(_delayedIncrement);
      addTearDown(a.dispose);

      final first = a.channel.messages.first;
      a.channel.send(const Num(1));
      expect((await first).value, 2);
    });

    test('independent actors do not share messages', () async {
      final a = await actor<Num, Num>(_double);
      final b = await actor<Num, Num>(_delayedIncrement);
      addTearDown(a.dispose);
      addTearDown(b.dispose);

      final fromA = a.channel.messages.first;
      final fromB = b.channel.messages.first;
      a.channel.send(const Num(10));
      b.channel.send(const Num(10));

      expect((await fromA).value, 20);
      expect((await fromB).value, 11);
    });

    test(
      'distinct types: send the input type, receive the output type',
      () async {
        final a = await actor<Response, Request>(_toResponse);
        addTearDown(a.dispose);

        // Compile-time check as much as a runtime one: send takes Request,
        // messages yields Response.
        final Stream<Response> responses = a.channel.messages;
        final reply = responses.first;
        a.channel.send(const Request(3));
        expect((await reply.timeout(wait)).text, 'n=3');
      },
    );
  });

  group('actor dispose', () {
    test('stops responding after dispose', () async {
      final a = await actor<Num, Num>(_double);
      final first = a.channel.messages.first;
      a.channel.send(const Num(1));
      expect((await first).value, 2);

      await a.dispose();

      final received = <Num>[];
      a.channel.messages.listen(received.add, onError: (_) {});
      try {
        a.channel.send(const Num(2));
      } catch (_) {
        // sending to a dead isolate may throw; either outcome is acceptable
      }
      await Future.delayed(const Duration(milliseconds: 300));
      expect(received, isEmpty);
    });

    test('calling dispose twice does not throw', () async {
      final a = await actor<Num, Num>(_double);
      await a.dispose();
      await a.dispose();
    });

    test('disposing one actor leaves others working', () async {
      final a = await actor<Num, Num>(_double);
      final b = await actor<Num, Num>(_double);
      addTearDown(b.dispose);
      await a.dispose();

      final reply = b.channel.messages.first;
      b.channel.send(const Num(5));
      expect((await reply.timeout(wait)).value, 10);
    });
  });

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
      await a.dispose();
      expect(await a.closed.timeout(wait), isNull);
    });

    test('completes with the error when the reducer throws', () async {
      final a = await actor<Num, Num>(_failOnNegative);
      addTearDown(a.dispose);

      a.channel.send(const Num(-1));
      final error = await a.closed.timeout(wait);

      expect(error, isNotNull);
      expect(error.toString(), contains('negative value: -1'));
    });

    test('captures errors thrown by asynchronous reducers', () async {
      final a = await actor<Num, Num>(_failAsync);
      addTearDown(a.dispose);

      a.channel.send(const Num(1));
      final error = await a.closed.timeout(wait);
      expect(error.toString(), contains('async failure'));
    });

    test('a failed actor stops processing further messages', () async {
      final a = await actor<Num, Num>(_failOnNegative);
      addTearDown(a.dispose);

      final received = <Num>[];
      a.channel.messages.listen(received.add, onError: (_) {});

      a.channel.send(const Num(-1));
      await a.closed.timeout(wait);
      try {
        a.channel.send(const Num(4));
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 200));
      expect(received, isEmpty);
    });

    test('messages sent before the failure are still answered', () async {
      final a = await actor<Num, Num>(_failOnNegative);
      addTearDown(a.dispose);

      final received = <Num>[];
      a.channel.messages.listen(received.add, onError: (_) {});

      a.channel.send(const Num(1));
      await Future.delayed(const Duration(milliseconds: 200));
      a.channel.send(const Num(-1));
      await a.closed.timeout(wait);
      expect(received.map((m) => m.value), [1]);
    });

    test('closes the response stream when the actor fails', () async {
      final a = await actor<Num, Num>(_failOnNegative);
      addTearDown(a.dispose);

      final done = a.channel.messages.drain<void>();
      a.channel.send(const Num(-1));
      await done.timeout(wait);
    });

    test('dispose after failure is harmless and keeps the error', () async {
      final a = await actor<Num, Num>(_failOnNegative);
      a.channel.send(const Num(-1));
      final error = await a.closed.timeout(wait);

      await a.dispose();
      expect(await a.closed, same(error));
    });

    test('a failing actor does not affect other actors', () async {
      final bad = await actor<Num, Num>(_failOnNegative);
      final good = await actor<Num, Num>(_failOnNegative);
      addTearDown(bad.dispose);
      addTearDown(good.dispose);

      bad.channel.send(const Num(-1));
      await bad.closed.timeout(wait);

      final reply = good.channel.messages.first;
      good.channel.send(const Num(3));
      expect((await reply.timeout(wait)).value, 3);

      var goodClosed = false;
      good.closed.then((_) => goodClosed = true);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(goodClosed, isFalse);
    });
  });
}
