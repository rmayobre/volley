import 'dart:isolate';

import 'package:test/test.dart';
import 'package:volley/src/actor/io/actor.dart' show spawnActor;
import 'package:volley/src/actor/io/isolate_actor_entrypoint.dart';
import 'package:volley/volley.dart';

final class Num implements Message {
  final int value;
  const Num(this.value);
}

Num _double(Num m) => Num(m.value * 2);

/// An entrypoint that fails before it can complete the handshake.
void _failsOnStartup(IsolateEntrypointArgs args) {
  throw StateError('startup failed');
}

/// An entrypoint that exits cleanly without ever completing the handshake.
void _exitsOnStartup(IsolateEntrypointArgs args) => Isolate.exit();

void main() {
  setUpAll(() => Bootstrapper.initialize());

  group('actor startup', () {
    test('throws the isolate error if it dies before the handshake', () async {
      await expectLater(
        spawnActor<Num, Num>(
          _double,
          entry: _failsOnStartup,
        ).timeout(const Duration(seconds: 5)),
        throwsA(
          isA<RemoteError>().having(
            (e) => e.toString(),
            'description',
            contains('startup failed'),
          ),
        ),
      );
    });

    test('throws a StateError if it exits without an error', () async {
      await expectLater(
        spawnActor<Num, Num>(
          _double,
          entry: _exitsOnStartup,
        ).timeout(const Duration(seconds: 5)),
        throwsA(isA<StateError>()),
      );
    });

    test('a failed startup does not affect later actors', () async {
      await spawnActor<Num, Num>(
        _double,
        entry: _failsOnStartup,
      ).then<void>((_) {}, onError: (_) {});

      final a = await actor<Num, Num>(_double);
      addTearDown(a.dispose);
      final reply = a.channel.messages.first;
      a.channel.send(const Num(4));
      expect((await reply.timeout(const Duration(seconds: 3))).value, 8);
    });
  });
}
