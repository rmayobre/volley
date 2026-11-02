
import 'package:test/test.dart';
import 'package:volley/volley.dart';

final class Num implements Message {
  final int value;
  const Num(this.value);
}

Num _failOnNegative(Num m) {
  if (m.value < 0) throw ArgumentError('negative');
  return Num(m.value);
}

// Separate file/process: a throwing reducer may kill the actor isolate.
void main() {
  setUpAll(() => Bootstrapper.initialize());

  test('a throwing reducer does not break other actors', () async {
    final bad = await actor<Num, Num>(_failOnNegative);
    final good = await actor<Num, Num>(_failOnNegative);
    addTearDown(bad.dispose);
    addTearDown(good.dispose);

    bad.channel.send(const Num(-1));
    final reply = good.channel.messages.first;
    good.channel.send(const Num(3));
    expect((await reply.timeout(const Duration(seconds: 3))).value, 3);
  });

  test('an actor keeps processing after its reducer throws once', () async {
    final a = await actor<Num, Num>(_failOnNegative);
    addTearDown(a.dispose);

    a.channel.send(const Num(-1));
    final reply = a.channel.messages.first;
    a.channel.send(const Num(4));
    expect((await reply.timeout(const Duration(seconds: 3))).value, 4);
  }, skip: 'BUG: an uncaught reducer error kills the actor isolate');
}
