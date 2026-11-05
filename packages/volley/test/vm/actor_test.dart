@TestOn('vm')
library;

import 'dart:async';

import 'package:test/test.dart';
import 'package:volley/volley.dart';

final class Num implements Message {
  final int value;
  const Num(this.value);
}

final class Tag implements Message {
  final String text;
  const Tag(this.text);
}

Num _double(Num m) => Num(m.value * 2);

Future<Num> _delayedIncrement(Num m) async {
  await Future.delayed(const Duration(milliseconds: 10));
  return Num(m.value + 1);
}

void main() {
  setUpAll(() => Bootstrapper.initialize());

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
      expect(await results, [2, 4, 6, 8, 10]);
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
      'rejects unsendable messages with UnsendableMessageException',
      () async {
        final a = await actor<_Boxed, _Boxed>((m) => m);
        addTearDown(a.dispose);
        var n = 0;
        expect(
          () => a.channel.send(_Boxed(() => n++)),
          throwsA(isA<UnsendableMessageException>()),
        );
      },
    );
  });
}

final class _Boxed implements Message {
  final Object payload;
  const _Boxed(this.payload);
}
