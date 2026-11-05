import 'dart:async';
import 'dart:isolate';

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

final class Flaky extends Singleton<Out, Cmd> {
  int _n = 0;

  @override
  Out reduce(Cmd event) {
    if (event.fail) throw StateError('singleton failed');
    return Out(++_n);
  }
}

final class Other extends Singleton<Out, Cmd> {
  @override
  Out reduce(Cmd event) => const Out(-1);
}

final class BrokenBuild extends Singleton<Out, Cmd> {
  BrokenBuild() {
    throw StateError('build failed');
  }

  @override
  Out reduce(Cmd event) => const Out(0);
}

final class Leaky implements Message {
  final ReceivePort port;
  Leaky(this.port);
}

final class LeakyOut extends Singleton<Leaky, Cmd> {
  @override
  Leaky reduce(Cmd event) => Leaky(ReceivePort());
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

      expect(outcomes, hasLength(3));
      expect((outcomes[0] as Out).n, 1);
      expect(outcomes[1], isA<StateError>());
      expect((outcomes[2] as Out).n, 2);
    });

    test('reports an unsendable response instead of crashing', () async {
      final ch = await Singleton.instance<Leaky, Cmd, LeakyOut>(LeakyOut.new);
      final failure = expectLater(
        ch.messages.first,
        throwsA(isA<UnsendableMessageException>()),
      );
      ch.send(const Cmd());
      await failure.timeout(wait);
      expect(await coroutine(() => 'ok').result.timeout(wait), 'ok');
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
