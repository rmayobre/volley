import 'dart:async';

import 'package:test/test.dart';
import 'package:volley/volley.dart';

sealed class CounterEvent implements Message {}

final class Add implements CounterEvent {
  final int amount;
  const Add(this.amount);
}

final class Clear implements CounterEvent {
  const Clear();
}

final class Total implements Message {
  final int value;
  const Total(this.value);
}

final class Counter extends SerializedSingleton<Total, CounterEvent> {
  int _total = 0;

  @override
  Total reduce(CounterEvent event) {
    switch (event) {
      case Add():
        _total += event.amount;
      case Clear():
        _total = 0;
    }
    return Total(_total);
  }
}

final class Echo extends SerializedSingleton<Total, Total> {
  @override
  Total reduce(Total event) => event;
}

Future<Channel<Total, CounterEvent>> _counter() =>
    Singleton.instance<Total, CounterEvent, Counter>(Counter.new);

void main() {
  setUpAll(() => Bootstrapper.initialize());

  group('Singleton', () {
    test('keeps state between messages', () async {
      final ch = await _counter();
      final cleared = ch.messages.first;
      ch.send(const Clear());
      await cleared;
      final totals = ch.messages.take(3).map((t) => t.value).toList();
      ch.send(const Add(2));
      ch.send(const Add(3));
      ch.send(const Add(5));
      expect(await totals, [2, 5, 10]);
    });

    test('instance() returns the cached channel for the same type', () async {
      final a = await _counter();
      final b = await _counter();
      expect(b, same(a));
    });

    test('ignores the factory on subsequent calls', () async {
      final first = await _counter();
      var builtAgain = false;
      final second = await Singleton.instance<Total, CounterEvent, Counter>(() {
        builtAgain = true;
        return Counter();
      });
      expect(second, same(first));
      expect(builtAgain, isFalse);
    });

    test('state is shared between channel users', () async {
      final ch = await _counter();
      final clearReply = ch.messages.first;
      ch.send(const Clear());
      expect((await clearReply).value, 0);

      final viaCoroutine =
          await coroutine(() async {
            final inner =
                await Singleton.instance<Total, CounterEvent, Counter>(
                  Counter.new,
                );
            final first = inner.messages.first;
            inner.send(const Add(100));
            return (await first).value;
          }).result;
      expect(viaCoroutine, greaterThanOrEqualTo(100));
    });

    test('different subtypes get different channels', () async {
      final counter = await _counter();
      final echo = await Singleton.instance<Total, Total, Echo>(Echo.new);
      expect(echo, isNot(same(counter)));

      final reply = echo.messages.first;
      echo.send(const Total(9));
      expect((await reply).value, 9);
    });
  });
}
