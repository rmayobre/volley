@TestOn('vm')
library;

import 'dart:isolate';

import 'package:test/test.dart';
import 'package:volley/volley.dart';

final class Num implements Message {
  final int value;
  const Num(this.value);
}

final class Boxed implements Message {
  final Object payload;
  const Boxed(this.payload);
}

Num _failOnNegative(Num m) {
  if (m.value < 0) throw ArgumentError('negative value: ${m.value}');
  return Num(m.value);
}

// Behaviour specific to isolate-backed actors. Shared behaviour lives in
// test/common/actor_test.dart.
void main() {
  setUpAll(() => Bootstrapper.initialize());

  test(
    'send rejects unsendable messages with UnsendableMessageException',
    () async {
      final a = await actor<Boxed, Boxed>((m) => m);
      addTearDown(a.dispose);
      var n = 0;
      expect(
        () => a.channel.send(Boxed(() => n++)),
        throwsA(isA<UnsendableMessageException>()),
      );
    },
  );

  test(
    'a reducer error reaches closed as a RemoteError with its trace',
    () async {
      final a = await actor<Num, Num>(_failOnNegative);
      addTearDown(a.dispose);

      a.channel.send(const Num(-1));
      final error = await a.closed.timeout(const Duration(seconds: 3));
      expect(error, isA<RemoteError>());
      expect((error as RemoteError).stackTrace.toString(), isNotEmpty);
    },
  );
}
