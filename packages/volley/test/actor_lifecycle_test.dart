import 'dart:async';

import 'package:test/test.dart';
import 'package:volley/volley.dart';

final class Num implements Message {
  final int value;
  const Num(this.value);
}

Num _double(Num m) => Num(m.value * 2);

void main() {
  setUpAll(() => Bootstrapper.initialize());

  group('Bootstrapper', () {
    test(
      'initialize can be called repeatedly',
      () async {
        await Bootstrapper.initialize();
        await Bootstrapper.initialize();
        expect(await coroutine(() => 1).result, 1);
      },
      skip: 'BUG: 2nd Bootstrapper.initialize() throws LateInitializationError',
    );
  });

  group('actor dispose', () {
    test('stops responding after dispose', () async {
      final a = await actor<Num, Num>(_double);
      final first = a.channel.messages.first;
      a.channel.send(const Num(1));
      expect((await first).value, 2);

      a.dispose();

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
      a.dispose();
      expect(a.dispose, returnsNormally);
    });

    test('disposing one actor leaves others working', () async {
      final a = await actor<Num, Num>(_double);
      final b = await actor<Num, Num>(_double);
      addTearDown(b.dispose);
      a.dispose();

      final reply = b.channel.messages.first;
      b.channel.send(const Num(5));
      expect((await reply).value, 10);
    });
  });
}
