@TestOn('vm')
library;

import 'dart:isolate';

import 'package:test/test.dart';
import 'package:volley/volley.dart';

final class Cmd implements Message {
  const Cmd();
}

final class Leaky implements Message {
  final ReceivePort port;
  Leaky(this.port);
}

final class LeakyOut extends Singleton<Leaky, Cmd> {
  @override
  Leaky reduce(Cmd event) => Leaky(ReceivePort());
}

// Own file (= own process): a mishandled failure would take down the shared
// singleton isolate.
void main() {
  setUpAll(() => Bootstrapper.initialize());

  const wait = Duration(seconds: 3);

  group('a Singleton whose reduce throws', () {
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
}
