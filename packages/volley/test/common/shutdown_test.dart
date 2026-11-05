import 'dart:async';

import 'package:test/test.dart';
import 'package:volley/volley.dart';

final class Msg implements Message {
  const Msg();
}

final class Count implements Message {
  final int calls;
  const Count(this.calls);
}

final class Stateful extends SerializedSingleton<Count, Msg> {
  int _calls = 0;

  @override
  Count reduce(Msg event) => Count(++_calls);
}

void main() {
  group('Bootstrapper.shutdown', () {
    test('is a no-op when never initialized', () async {
      await Bootstrapper.shutdown();
    });

    test('can be called twice', () async {
      await Bootstrapper.initialize();
      await Bootstrapper.shutdown();
      await Bootstrapper.shutdown();
    });

    test('initialize works again afterwards', () async {
      await Bootstrapper.initialize();
      expect(await coroutine(() => 1).result, 1);
      await Bootstrapper.shutdown();

      await Bootstrapper.initialize();
      expect(await coroutine(() => 2).result, 2);
      await Bootstrapper.shutdown();
    });

    test(
      'fails unfinished coroutines with CoroutineDisposedException',
      () async {
        await Bootstrapper.initialize();
        final c = coroutine(() => Completer<int>().future);
        final failure = expectLater(
          c.result.timeout(const Duration(seconds: 5)),
          throwsA(isA<CoroutineDisposedException>()),
        );

        await Bootstrapper.shutdown();
        await failure;
        expect(c.isCanceled, isTrue);
      },
    );

    test('singletons start from scratch after a restart', () async {
      Future<int> call() async {
        final ch = await Singleton.instance<Count, Msg, Stateful>(Stateful.new);
        final reply = ch.messages.first;
        ch.send(const Msg());
        return (await reply).calls;
      }

      await Bootstrapper.initialize();
      expect(await call(), 1);
      expect(await call(), 2);
      await Bootstrapper.shutdown();

      await Bootstrapper.initialize();
      expect(await call(), 1, reason: 'the old instance must be gone');
      await Bootstrapper.shutdown();
    });
  });
}
