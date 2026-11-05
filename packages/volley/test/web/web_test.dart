@TestOn('browser')
library;

import 'dart:async';

import 'package:test/test.dart';
import 'package:volley/volley.dart';

final class Num implements Message {
  final int value;
  const Num(this.value);
}

void main() {
  setUpAll(() => Bootstrapper.initialize());

  group('web coroutine', () {
    test('runs on the caller\'s own thread (no isolates on the web)', () async {
      var ran = false;
      await coroutine(() => ran = true).result;
      // A closure mutating local state only works if nothing was copied
      // across a thread boundary.
      expect(ran, isTrue);
    });

    test('a rejected future in the computation fails result', () async {
      await expectLater(
        coroutine<int>(() => Future.error(StateError('nope'))).result,
        throwsStateError,
      );
    });
  });

  group('web singleton', () {
    test('instance is built once and shared', () async {
      var builds = 0;
      final a = await Singleton.instance<Num, Num, _Doubler>(() {
        builds++;
        return _Doubler();
      });
      final b = await Singleton.instance<Num, Num, _Doubler>(() {
        builds++;
        return _Doubler();
      });
      expect(b, same(a));
      expect(builds, 1);
    });

    test('reduce runs in-process and replies', () async {
      final ch = await Singleton.instance<Num, Num, _Doubler>(_Doubler.new);
      final reply = ch.messages.first;
      ch.send(const Num(21));
      expect((await reply).value, 42);
    });
  });

  group('web actor', () {
    test('may use a closure over local state as its reducer', () async {
      // Only possible because nothing is sent across an isolate boundary.
      var calls = 0;
      final a = await actor<Num, Num>((m) {
        calls++;
        return Num(m.value + calls);
      });
      addTearDown(a.dispose);

      final reply = a.channel.messages.first;
      a.channel.send(const Num(10));
      expect((await reply).value, 11);
      expect(calls, 1);
    });

    test('handles messages one at a time, in order', () async {
      // The first message is the slowest; a concurrent implementation would
      // answer it last.
      final a = await actor<Num, Num>((m) async {
        await Future.delayed(Duration(milliseconds: 30 - m.value * 10));
        return m;
      });
      addTearDown(a.dispose);

      final replies = a.channel.messages.take(3).map((m) => m.value).toList();
      for (var i = 0; i < 3; i++) {
        a.channel.send(Num(i));
      }
      expect(await replies, [0, 1, 2]);
    });
  });
}

final class _Doubler extends SerializedSingleton<Num, Num> {
  @override
  Num reduce(Num event) => Num(event.value * 2);
}
