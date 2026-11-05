import 'dart:async';

import 'package:test/test.dart';
import 'package:volley/volley.dart';

final class Cmd implements Message {
  final bool fail;
  const Cmd({this.fail = false});
}

final class Out implements Message {
  final int n;
  const Out(this.n);
}

final class Flaky extends SerializedSingleton<Out, Cmd> {
  int _n = 0;

  @override
  Out reduce(Cmd event) {
    if (event.fail) throw StateError('singleton failed');
    return Out(++_n);
  }
}

final class Other extends SerializedSingleton<Out, Cmd> {
  @override
  Out reduce(Cmd event) => const Out(-1);
}

final class BrokenBuild extends SerializedSingleton<Out, Cmd> {
  BrokenBuild() {
    throw StateError('build failed');
  }

  @override
  Out reduce(Cmd event) => const Out(0);
}

// Own file (= own process): these tests exercise failures that, if mishandled,
// would take down the shared singleton isolate.
void main() {
  setUpAll(() => Bootstrapper.initialize());

  const wait = Duration(seconds: 3);

  group('a Singleton whose reduce throws', () {
    test('reports the error on the channel stream', () async {
      final ch = await Singleton.instance<Out, Cmd, Flaky>(Flaky.new);
      final failure = expectLater(
        ch.messages.first,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'singleton failed',
          ),
        ),
      );
      ch.send(const Cmd(fail: true));
      await failure.timeout(wait);
    });

    test('does not break coroutines', () async {
      final ch = await Singleton.instance<Out, Cmd, Flaky>(Flaky.new);
      ch.messages.listen((_) {}, onError: (_) {});
      ch.send(const Cmd(fail: true));
      await Future.delayed(const Duration(milliseconds: 200));
      expect(await coroutine(() => 'ok').result.timeout(wait), 'ok');
    });

    test('does not break other singletons', () async {
      final flaky = await Singleton.instance<Out, Cmd, Flaky>(Flaky.new);
      final other = await Singleton.instance<Out, Cmd, Other>(Other.new);
      flaky.messages.listen((_) {}, onError: (_) {});
      flaky.send(const Cmd(fail: true));

      final reply = other.messages.first;
      other.send(const Cmd());
      expect((await reply.timeout(wait)).n, -1);
    });

    test('keeps its state and keeps working afterwards', () async {
      final ch = await Singleton.instance<Out, Cmd, Flaky>(Flaky.new);
      final outcomes = <Object>[];
      ch.messages.listen(outcomes.add, onError: outcomes.add);

      ch.send(const Cmd());
      ch.send(const Cmd(fail: true));
      ch.send(const Cmd());
      await Future.delayed(const Duration(milliseconds: 500));

      // Delivery order between concurrent messages isn't guaranteed, so only
      // check what arrived: one error, plus two successful, counted replies.
      expect(outcomes, hasLength(3));
      expect(outcomes.whereType<StateError>(), hasLength(1));
      expect(outcomes.whereType<Out>().map((o) => o.n).toList()..sort(), [
        1,
        2,
      ]);
    });
  });

  group('error delivery contract', () {
    test(
      'an error nobody handles is uncaught, like any stream error',
      () async {
        final uncaught = <Object>[];
        await runZonedGuarded(() async {
          final ch = await Singleton.instance<Out, Cmd, Flaky>(Flaky.new);
          ch.messages.listen((_) {}); // no onError
          ch.send(const Cmd(fail: true));
          await Future.delayed(const Duration(milliseconds: 300));
        }, (error, stack) => uncaught.add(error));

        expect(uncaught, hasLength(1));
        expect(uncaught.single, isA<StateError>());
      },
    );

    test('onError and handleError both keep the error from escaping', () async {
      final uncaught = <Object>[];
      final seen = <Object>[];
      await runZonedGuarded(() async {
        final ch = await Singleton.instance<Out, Cmd, Flaky>(Flaky.new);
        ch.messages.listen((_) {}, onError: seen.add);
        ch.messages.handleError(seen.add).listen((_) {});
        ch.send(const Cmd(fail: true));
        await Future.delayed(const Duration(milliseconds: 300));
      }, (error, stack) => uncaught.add(error));

      expect(uncaught, isEmpty);
      expect(seen, hasLength(2));
    });

    test('the error keeps the original stack trace', () async {
      final ch = await Singleton.instance<Out, Cmd, Flaky>(Flaky.new);
      final captured = Completer<StackTrace>();
      ch.messages.listen(
        (_) {},
        onError: (Object e, StackTrace st) {
          if (!captured.isCompleted) captured.complete(st);
        },
      );
      ch.send(const Cmd(fail: true));
      final st = await captured.future.timeout(const Duration(seconds: 3));
      expect(st.toString(), contains('reduce'));
    });
  });

  group('Singleton.instance', () {
    test('throws when the singleton fails to build', () async {
      await expectLater(
        Singleton.instance<Out, Cmd, BrokenBuild>(
          BrokenBuild.new,
        ).timeout(wait),
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', 'build failed'),
        ),
      );
      expect(await coroutine(() => 'ok').result.timeout(wait), 'ok');
    });
  });
}
