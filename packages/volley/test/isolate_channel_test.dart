import 'dart:async';

import 'package:test/test.dart';
import 'package:volley/volley.dart';

final class Ping implements Message {
  final Object payload;
  const Ping(this.payload);
}

FutureOr<Ping> _echoReducer(Ping message) async => message;

void main() {
  // Without this, the first actor() call in the isolate has no existing
  // singleton coordinator to defer to, so it becomes one for itself — but
  // its own reducer only accepts Ping messages, so the SingletonInit message
  // Bootstrapper.initialize() sends it (for CoroutineExecutor) is silently
  // dropped and the test hangs forever awaiting a reply. Matches the same
  // setUpAll pattern used in packages/volley_workers/test/native_test.dart.
  setUpAll(() => Bootstrapper.initialize());

  test('IsolateChannel.send throws UnsendableMessageException for a message '
      'that cannot cross the isolate boundary', () async {
    final a = await actor<Ping, Ping>(_echoReducer);
    addTearDown(a.dispose);

    // A closure that captures local mutable state cannot be sent across
    // an isolate boundary — SendPort.send throws ArgumentError for it.
    var counter = 0;
    int unsendableClosure() => counter++;

    expect(
      () => a.channel.send(Ping(unsendableClosure)),
      throwsA(isA<UnsendableMessageException>()),
    );
  });
}
