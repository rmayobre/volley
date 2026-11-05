@TestOn('browser')
library;

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
    test('closed is pending until dispose, then completes with null', () async {
      final a = await actor<Num, Num>(_double);
      var done = false;
      a.closed.then((_) => done = true);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(done, isFalse);

      await a.dispose();
      expect(await a.closed, isNull);
    });

    test('dispose twice does not throw', () async {
      final a = await actor<Num, Num>(_double);
      await a.dispose();
      await a.dispose();
    });
  });
}

final class _Doubler extends Singleton<Num, Num> {
  @override
  Num reduce(Num event) => Num(event.value * 2);
}
